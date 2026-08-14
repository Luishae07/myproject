// YouTube-only video crawler. Fetches YouTube search results pages for a
// sharded slice of seed queries, pulls video metadata out of the
// `ytInitialData` JSON blob YouTube embeds in the page (no API key needed),
// and POSTs batches to Luisearch's existing /api/crawl-ingest endpoint.
//
// Sharding: pass --shard-index N --shard-total M and this process only
// handles queries where (index_in_list % M == N) -- lets a GitHub Actions
// matrix split one big query list across many parallel jobs/IPs.

use serde_json::Value;
use std::env;
use std::fs;
use std::time::Duration;

#[derive(Default, Clone)]
struct VideoEntry {
    url: String,
    title: String,
    channel: String,
    duration: String,
    thumbnail: String,
    description: String,
}

fn extract_yt_initial_data(html: &str) -> Option<Value> {
    let marker = "var ytInitialData = ";
    let start = html.find(marker)? + marker.len();
    let rest = &html[start..];
    // YouTube always terminates this assignment with `;</script>` -- good
    // enough in practice (this is the same technique every YouTube scraper
    // uses; a literal `;</script>` inside a JSON string value is not
    // something YouTube's own metadata actually contains).
    let end = rest.find(";</script>")?;
    serde_json::from_str(&rest[..end]).ok()
}

// Recursively walks the parsed JSON looking for any object with a
// "videoRenderer" key -- robust to YouTube changing the surrounding page
// structure, since we don't hardcode the full nested path to get there.
fn find_video_renderers<'a>(value: &'a Value, out: &mut Vec<&'a Value>) {
    match value {
        Value::Object(map) => {
            if let Some(vr) = map.get("videoRenderer") {
                out.push(vr);
            }
            for v in map.values() {
                find_video_renderers(v, out);
            }
        }
        Value::Array(arr) => {
            for v in arr {
                find_video_renderers(v, out);
            }
        }
        _ => {}
    }
}

fn text_from_runs(v: &Value) -> String {
    v.get("runs")
        .and_then(|r| r.as_array())
        .map(|runs| {
            runs.iter()
                .filter_map(|r| r.get("text").and_then(|t| t.as_str()))
                .collect::<String>()
        })
        .or_else(|| v.get("simpleText").and_then(|t| t.as_str()).map(String::from))
        .unwrap_or_default()
}

fn parse_video_renderer(vr: &Value) -> Option<VideoEntry> {
    let video_id = vr.get("videoId")?.as_str()?.to_string();
    let title = text_from_runs(vr.get("title")?);
    if title.is_empty() {
        return None;
    }
    let channel = vr
        .get("ownerText")
        .map(text_from_runs)
        .unwrap_or_default();
    let duration = vr
        .get("lengthText")
        .map(text_from_runs)
        .unwrap_or_default();
    let thumbnail = vr
        .get("thumbnail")
        .and_then(|t| t.get("thumbnails"))
        .and_then(|t| t.as_array())
        .and_then(|arr| arr.last())
        .and_then(|t| t.get("url"))
        .and_then(|u| u.as_str())
        .unwrap_or_default()
        .to_string();
    let description = vr
        .get("descriptionSnippet")
        .map(text_from_runs)
        .unwrap_or_default();

    Some(VideoEntry {
        url: format!("https://www.youtube.com/watch?v={video_id}"),
        title,
        channel,
        duration,
        thumbnail,
        description,
    })
}

fn search_youtube(client: &reqwest::blocking::Client, query: &str) -> Vec<VideoEntry> {
    let url = format!(
        "https://www.youtube.com/results?search_query={}",
        urlencoding_encode(query)
    );
    let resp = match client
        .get(&url)
        .header(
            "User-Agent",
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 \
             (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
        )
        .header("Accept-Language", "en-US,en;q=0.9")
        .send()
    {
        Ok(r) => r,
        Err(e) => {
            eprintln!("fetch failed for {query:?}: {e}");
            return Vec::new();
        }
    };
    let html = match resp.text() {
        Ok(t) => t,
        Err(e) => {
            eprintln!("read body failed for {query:?}: {e}");
            return Vec::new();
        }
    };
    let data = match extract_yt_initial_data(&html) {
        Some(d) => d,
        None => {
            eprintln!("no ytInitialData found for {query:?} (page shape changed, or blocked)");
            return Vec::new();
        }
    };
    let mut renderers = Vec::new();
    find_video_renderers(&data, &mut renderers);
    renderers.iter().filter_map(|vr| parse_video_renderer(vr)).collect()
}

// Tiny percent-encoder -- avoids pulling in the `url`/`urlencoding` crate
// for one call site.
fn urlencoding_encode(s: &str) -> String {
    let mut out = String::new();
    for b in s.bytes() {
        match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' => {
                out.push(b as char)
            }
            _ => out.push_str(&format!("%{:02X}", b)),
        }
    }
    out
}

fn ingest_batch(client: &reqwest::blocking::Client, ingest_url: &str, token: &str, videos: &[VideoEntry]) {
    if videos.is_empty() {
        return;
    }
    let body = serde_json::json!({
        "pages": [],
        "videos": videos.iter().map(|v| serde_json::json!({
            "url": v.url, "title": v.title, "channel": v.channel,
            "duration": v.duration, "thumbnail": v.thumbnail, "description": v.description,
        })).collect::<Vec<_>>(),
    });
    match client
        .post(ingest_url)
        .header("Authorization", format!("Bearer {token}"))
        .json(&body)
        .send()
    {
        Ok(resp) => {
            let status = resp.status();
            let text = resp.text().unwrap_or_default();
            println!("ingest batch of {}: {status} {text}", videos.len());
        }
        Err(e) => eprintln!("ingest failed: {e}"),
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let mut queries_file = "queries.txt".to_string();
    let mut shard_index: usize = 0;
    let mut shard_total: usize = 1;
    let mut i = 1;
    while i < args.len() {
        match args[i].as_str() {
            "--queries-file" => {
                i += 1;
                queries_file = args[i].clone();
            }
            "--shard-index" => {
                i += 1;
                shard_index = args[i].parse().unwrap_or(0);
            }
            "--shard-total" => {
                i += 1;
                shard_total = args[i].parse().unwrap_or(1).max(1);
            }
            _ => {}
        }
        i += 1;
    }

    let ingest_url = env::var("INGEST_URL").expect("INGEST_URL env var required");
    let ingest_token = env::var("INGEST_TOKEN").expect("INGEST_TOKEN env var required");

    let all_queries: Vec<String> = fs::read_to_string(&queries_file)
        .unwrap_or_else(|e| panic!("could not read {queries_file}: {e}"))
        .lines()
        .map(|l| l.trim().to_string())
        .filter(|l| !l.is_empty())
        .collect();

    let my_queries: Vec<&String> = all_queries
        .iter()
        .enumerate()
        .filter(|(idx, _)| idx % shard_total == shard_index)
        .map(|(_, q)| q)
        .collect();

    println!(
        "shard {}/{}: {} of {} total queries",
        shard_index,
        shard_total,
        my_queries.len(),
        all_queries.len()
    );

    let client = reqwest::blocking::Client::builder()
        .timeout(Duration::from_secs(20))
        .build()
        .expect("failed to build HTTP client");

    let mut batch: Vec<VideoEntry> = Vec::new();
    for query in my_queries {
        let results = search_youtube(&client, query);
        println!("{query:?}: {} videos", results.len());
        batch.extend(results);
        if batch.len() >= 200 {
            ingest_batch(&client, &ingest_url, &ingest_token, &batch);
            batch.clear();
        }
        // Be a decent citizen -- this is a search-results page fetch, not
        // an API call, and hammering it risks getting the runner's IP
        // rate-limited or CAPTCHA'd mid-shard.
        std::thread::sleep(Duration::from_millis(800));
    }
    ingest_batch(&client, &ingest_url, &ingest_token, &batch);
}
