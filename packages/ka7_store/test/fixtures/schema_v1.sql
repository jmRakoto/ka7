-- Ka7 store schema v1, as written by ka7_store 0.1.0.
CREATE TABLE "archive_entries" ("video_id" TEXT NOT NULL, "format" TEXT NOT NULL, PRIMARY KEY ("video_id", "format"));
CREATE TABLE "history_entries" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "video_id" TEXT NOT NULL, "title" TEXT NOT NULL, "album" TEXT NULL, "format" TEXT NOT NULL, "status" TEXT NOT NULL, "path" TEXT NULL, "reason" TEXT NULL, "message" TEXT NULL, "at" INTEGER NOT NULL);
INSERT INTO archive_entries (video_id, format) VALUES ('jNQXAC9IVRw', 'mp3');
PRAGMA user_version = 1;
