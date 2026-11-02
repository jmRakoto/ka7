-- Ka7 store schema v4, as written by ka7_store before subscriptions.
CREATE TABLE "archive_entries" ("video_id" TEXT NOT NULL, "format" TEXT NOT NULL, PRIMARY KEY ("video_id", "format"));
CREATE TABLE "history_entries" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "video_id" TEXT NOT NULL, "title" TEXT NOT NULL, "album" TEXT NULL, "playlist_id" TEXT NULL, "format" TEXT NOT NULL, "status" TEXT NOT NULL, "path" TEXT NULL, "reason" TEXT NULL, "message" TEXT NULL, "at" INTEGER NOT NULL);
CREATE TABLE "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"));
CREATE TABLE "pending_downloads" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "format" TEXT NOT NULL, "folder" TEXT NOT NULL, "source_title" TEXT NOT NULL, "source_playlist_id" TEXT NULL, "source_is_channel" INTEGER NOT NULL CHECK ("source_is_channel" IN (0, 1)), "video_id" TEXT NOT NULL, "title" TEXT NOT NULL, "channel" TEXT NULL, "duration_seconds" INTEGER NULL, "position" INTEGER NOT NULL);
INSERT INTO archive_entries (video_id, format) VALUES ('jNQXAC9IVRw', 'mp3');
INSERT INTO settings (key, value) VALUES ('language', 'fr');
PRAGMA user_version = 4;
