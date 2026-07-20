require("dotenv").config();
const express = require("express");
const cors = require("cors");

if (!process.env.JWT_SECRET) {
  throw new Error("JWT_SECRET is not set. Add it to backend/.env before starting the server.");
}

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

app.listen(port, () => {
  console.log(`🚀 Server running at http://localhost:${port}`);
});
