import mysql from "mysql2/promise";

const pool = mysql.createPool({
  host: process.env.DB_HOST ?? "127.0.0.1",
  port: Number(process.env.DB_PORT ?? 3306),
  database: process.env.DB_NAME ?? "searchdb",
  user: process.env.DB_USER ?? "admin",
  password: process.env.DB_PASSWORD ?? "",
  connectionLimit: 5,
  waitForConnections: true
});

export async function logSearch(searchTerm) {
  await pool.execute(
    "INSERT INTO `2400620` (search_query, query_time) VALUES (?, UTC_TIMESTAMP())",
    [searchTerm]
  );
}

export async function databaseIsReady() {
  await pool.query("SELECT 1");
}
