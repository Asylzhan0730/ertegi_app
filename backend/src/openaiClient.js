const axios = require("axios");

function getLanguageInstruction(language) {
  if (language === "ru") {
    return "Отвечай строго только на русском языке. Не используй казахский или английский язык.";
  }

  if (language === "en") {
    return "Answer strictly only in English. Do not use Kazakh or Russian.";
  }

  return "Тек қазақ тілінде жауап бер. Орысша немесе ағылшынша жазба.";
}

async function generateStoryWithAI({
  prompt,
  ageCategory,
  category,
  language,
  originalStory,
}) {
  if (!process.env.OPENROUTER_API_KEY) {
    throw new Error("OPENROUTER_API_KEY .env ішінде жоқ");
  }

  const languageInstruction = getLanguageInstruction(language);

  const finalPrompt = originalStory
    ? `
${languageInstruction}

You are a safe children's fairy tale narrator.

Use the ORIGINAL fairy tale below as the source.
Do not invent a new plot.
Keep the main story meaning.
If the original is in another language, translate and retell it in the selected language.
Make it suitable for this age group: ${ageCategory || "5+"}.
Category: ${category || "Classic fairy tale"}.

ORIGINAL FAIRY TALE:
${originalStory}
`
    : `
${languageInstruction}

You are a safe children's fairy tale writer.
Write a kind, warm, educational fairy tale.
Make it suitable for this age group: ${ageCategory || "5+"}.
Category: ${category || "Classic fairy tale"}.

User request:
${prompt}
`;

  const response = await axios.post(
    "https://openrouter.ai/api/v1/chat/completions",
    {
      model: process.env.OPENROUTER_MODEL || "openai/gpt-4o-mini",
      messages: [
        {
          role: "system",
          content: `${languageInstruction} You write safe fairy tales for children.`,
        },
        {
          role: "user",
          content: finalPrompt,
        },
      ],
      temperature: originalStory ? 0.3 : 0.8,
      max_tokens: 1600,
    },
    {
      headers: {
        Authorization: `Bearer ${process.env.OPENROUTER_API_KEY}`,
        "Content-Type": "application/json",
        "HTTP-Referer": process.env.SITE_URL || "http://localhost:3000",
        "X-Title": process.env.APP_NAME || "Ertegi AI",
      },
    }
  );

  return response.data.choices[0].message.content;
}

module.exports = {
  generateStoryWithAI,
};