const express = require("express");
const cors = require("cors");

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

app.use("/profile", require("./routes/profile"));

// Routes
app.use("/auth", require("./routes/auth"));

//Matches
app.use("/matches", require("./routes/matches"));

//Requests
app.use("/requests", require("./routes/requests"));

//Responses
app.use("/responses", require("./routes/responses"));

app.get("/", (req, res) => {
  res.send("Blood Donation App API is running...");
});
app.get("/dev/users", async (req, res) => {
  const db = require("./db/db");
  try {
    const rows = await db.allAsync("SELECT id, name, latitude, longitude FROM users");
    res.json({ users: rows });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.listen(port, () => {
  console.log(`🚀 Server running at http://localhost:${port}`);
});
