const express = require("express");
const cors = require("cors");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
require("dotenv").config();

const db = require("./db");
const authMiddleware = require("./middleware");
const { generateStoryWithAI } = require("./openaiClient");
const { searchErtegiOnInternet } = require("./storySearch");
const { generateSpeechUrl } = require("./tts");

const app = express();

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "Ertegi AI backend is running",
  });
});

app.post("/api/tts", async (req, res) => {
  try {
    const { text } = req.body;
    const url = await generateSpeechUrl(text);
    res.json({ url });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
});

app.post("/api/auth/register", async (req, res) => {
  try {
    const { email, password, ageCategory } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email және password керек",
      });
    }

    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    if (!emailRegex.test(String(email))) {
      return res.status(400).json({
        success: false,
        message: "Дұрыс email енгізіңіз. Мысалы: user@gmail.com",
      });
    }

    const hashedPassword = await bcrypt.hash(String(password), 10);

    db.run(
      `INSERT INTO users (email, password, age_category) VALUES (?, ?, ?)`,
      [String(email), hashedPassword, ageCategory || "5+"],
      function (err) {
        if (err) {
          return res.status(400).json({
            success: false,
            message: "Бұл email бұрын тіркелген",
          });
        }

        const token = jwt.sign(
          { id: this.lastID, email: String(email) },
          process.env.JWT_SECRET || "secret",
          { expiresIn: "7d" }
        );

        res.json({
          success: true,
          token,
          email: String(email),
          ageCategory: ageCategory || "5+",
        });
      }
    );
  } catch (e) {
    res.status(500).json({
      success: false,
      message: e.message,
    });
  }
});

app.post("/api/auth/login", (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email және password керек",
      });
    }

    db.get(
      `SELECT * FROM users WHERE email = ?`,
      [String(email)],
      async (err, user) => {
        if (err || !user || !user.password) {
          return res.status(400).json({
            success: false,
            message: "Email немесе password қате",
          });
        }

        if (user.password === "GOOGLE_ACCOUNT") {
          return res.status(400).json({
            success: false,
            message: "Бұл аккаунт Google арқылы тіркелген",
          });
        }

        const ok = await bcrypt.compare(String(password), String(user.password));

        if (!ok) {
          return res.status(400).json({
            success: false,
            message: "Email немесе password қате",
          });
        }

        const token = jwt.sign(
          { id: user.id, email: user.email },
          process.env.JWT_SECRET || "secret",
          { expiresIn: "7d" }
        );

        res.json({
          success: true,
          token,
          email: user.email,
          ageCategory: user.age_category || "5+",
        });
      }
    );
  } catch (e) {
    res.status(500).json({
      success: false,
      message: e.message,
    });
  }
});

app.post("/api/auth/google", (req, res) => {
  try {
    const { email, firebaseUid } = req.body;

    if (!email || !firebaseUid) {
      return res.status(400).json({
        success: false,
        message: "Google email немесе firebaseUid жоқ",
      });
    }

    db.get(`SELECT * FROM users WHERE email = ?`, [email], (err, user) => {
      if (err) {
        return res.status(500).json({
          success: false,
          message: "Database қатесі",
        });
      }

      if (user) {
        const token = jwt.sign(
          { id: user.id, email: user.email },
          process.env.JWT_SECRET || "secret",
          { expiresIn: "7d" }
        );

        return res.json({
          success: true,
          token,
          email: user.email,
          ageCategory: user.age_category || "5+",
        });
      }

      db.run(
        `INSERT INTO users (email, password, age_category) VALUES (?, ?, ?)`,
        [email, "GOOGLE_ACCOUNT", "5+"],
        function (err) {
          if (err) {
            return res.status(500).json({
              success: false,
              message: "Google аккаунт сақтау қатесі",
            });
          }

          const token = jwt.sign(
            { id: this.lastID, email },
            process.env.JWT_SECRET || "secret",
            { expiresIn: "7d" }
          );

          res.json({
            success: true,
            token,
            email,
            ageCategory: "5+",
          });
        }
      );
    });
  } catch (e) {
    res.status(500).json({
      success: false,
      message: e.message,
    });
  }
});

app.post("/api/filter", authMiddleware, (req, res) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: "Авторизация керек",
    });
  }

  const { ageCategory } = req.body;

  db.run(
    `UPDATE users SET age_category = ? WHERE id = ?`,
    [ageCategory || "5+", req.user.id],
    function (err) {
      if (err) {
        return res.status(500).json({
          success: false,
          message: "Фильтр сақталмады",
        });
      }

      res.json({
        success: true,
        ageCategory: ageCategory || "5+",
      });
    }
  );
});

app.post("/api/story/generate", authMiddleware, async (req, res) => {
  try {
    console.log("GENERATE USER:", req.user);

    const prompt = req.body.prompt || "Қазақша қысқа ертегі жаз";
    const ageCategory = req.body.ageCategory || "5+";
    const category = req.body.category || "Классикалық ертегі";
    const language = req.body.language || "kk";

    let original = null;

    try {
      original = await searchErtegiOnInternet(prompt);
    } catch (e) {
      console.log("SEARCH ERROR:", e.message);
    }

    const story = await generateStoryWithAI({
      prompt,
      ageCategory,
      category,
      language,
      originalStory: original?.text || null,
    });

    if (req.user) {
      db.run(
        `INSERT INTO stories (user_id, prompt, story, age_category, category) VALUES (?, ?, ?, ?, ?)`,
        [req.user.id, prompt, story, ageCategory, category],
        function (err) {
          if (err) {
            console.log("AUTO SAVE STORY ERROR:", err.message);
          } else {
            console.log("AUTO SAVED STORY ID:", this.lastID);
          }
        }
      );
    }

    res.json({
      success: true,
      story,
      source: original
        ? {
            url: original.url,
            title: original.title || "Ертегі",
          }
        : null,
    });
  } catch (e) {
    console.log("OPENROUTER ERROR:", e.response?.data || e.message);

    res.status(500).json({
      success: false,
      message: "OpenRouter AI қатесі",
      error: e.response?.data || e.message,
    });
  }
});

app.post("/api/stories", authMiddleware, (req, res) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: "Авторизация керек",
    });
  }

  const { prompt, story } = req.body;

  if (!story) {
    return res.status(400).json({
      success: false,
      message: "story жоқ",
    });
  }

  db.run(
    `INSERT INTO stories (user_id, prompt, story, age_category, category) VALUES (?, ?, ?, ?, ?)`,
    [req.user.id, prompt || "", story, "5+", "manual"],
    function (err) {
      if (err) {
        console.log("MANUAL SAVE STORY ERROR:", err.message);

        return res.status(500).json({
          success: false,
          message: "Ертегі сақталмады",
          error: err.message,
        });
      }

      res.json({
        success: true,
        id: this.lastID,
        message: "Ертегі сақталды",
      });
    }
  );
});

app.get("/api/stories", authMiddleware, (req, res) => {
  if (!req.user) {
    return res.status(401).json({
      success: false,
      message: "Авторизация керек",
    });
  }

  db.all(
    `SELECT * FROM stories WHERE user_id = ? ORDER BY created_at DESC`,
    [req.user.id],
    (err, rows) => {
      if (err) {
        return res.status(500).json({
          success: false,
          message: "Ертегілер алынбады",
        });
      }

      res.json({
        success: true,
        stories: rows,
      });
    }
  );
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Backend running: http://localhost:${PORT}`);
});