const axios = require("axios");
const cheerio = require("cheerio");

const KNOWN_STORIES = [
  {
    keys: ["бауырсақ", "бауырсак", "kolobok"],
    url: "https://ertegiler.kz/story/bauirsak",
  },
  {
    keys: ["мақта қыз", "макта кыз", "мақта қыз бен мысық", "макта кыз бен мысык"],
    url: "https://ertegiler.kz/story/makta-kyz-ben-mysyk",
  },
  {
    keys: ["жеті қарақшы", "жети каракшы", "7 қарақшы", "7 каракшы"],
    url: "https://ertegiler.kz/story/zheti-qaraqshy-ertegi",
  },
];

function normalize(text) {
  return String(text || "")
    .toLowerCase()
    .replace(/ә/g, "а")
    .replace(/і/g, "и")
    .replace(/ң/g, "н")
    .replace(/ғ/g, "г")
    .replace(/ү/g, "у")
    .replace(/ұ/g, "у")
    .replace(/қ/g, "к")
    .replace(/ө/g, "о")
    .replace(/һ/g, "х")
    .replace(/[^a-zа-я0-9\s]/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

function findKnownStoryUrl(query) {
  const q = normalize(query);

  for (const item of KNOWN_STORIES) {
    for (const key of item.keys) {
      if (q.includes(normalize(key))) {
        return item.url;
      }
    }
  }

  return null;
}

function cleanText(text) {
  return String(text || "")
    .replace(/\s+/g, " ")
    .replace(/Таңдаулыға қосу/gi, "")
    .replace(/Жаңа вкладкада ашу/gi, "")
    .replace(/мультфильмін көру/gi, "")
    .trim();
}

async function parseErtegiPage(url) {
  const response = await axios.get(url, {
    headers: {
      "User-Agent": "Mozilla/5.0",
    },
    timeout: 15000,
  });

  const $ = cheerio.load(response.data);

  const title = cleanText($("h1").first().text()) || "Ертегі";
  let text = "";

  $("p").each((i, el) => {
    const paragraph = cleanText($(el).text());

    if (
      paragraph.length > 20 &&
      !paragraph.toLowerCase().includes("youtube") &&
      !paragraph.toLowerCase().includes("пікір") &&
      !paragraph.toLowerCase().includes("cookie")
    ) {
      text += paragraph + "\n\n";
    }
  });

  text = text.trim();

  if (text.length < 150) {
    return null;
  }

  return {
    title,
    url,
    text,
  };
}

async function searchErtegiOnInternet(query) {
  const knownUrl = findKnownStoryUrl(query);

  if (knownUrl) {
    return await parseErtegiPage(knownUrl);
  }

  return null;
}

module.exports = {
  searchErtegiOnInternet,
};