-- Ka7 store schema v5, as written by ka7_store before download quality.
CREATE TABLE IF NOT EXISTS "archive_entries" ("video_id" TEXT NOT NULL, "format" TEXT NOT NULL, PRIMARY KEY ("video_id", "format"));
INSERT INTO archive_entries VALUES('jNQXAC9IVRw','mp3');
CREATE TABLE IF NOT EXISTS "history_entries" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "video_id" TEXT NOT NULL, "title" TEXT NOT NULL, "album" TEXT NULL, "playlist_id" TEXT NULL, "format" TEXT NOT NULL, "status" TEXT NOT NULL, "path" TEXT NULL, "reason" TEXT NULL, "message" TEXT NULL, "at" INTEGER NOT NULL);
CREATE TABLE IF NOT EXISTS "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"));
CREATE TABLE IF NOT EXISTS "pending_downloads" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "format" TEXT NOT NULL, "folder" TEXT NOT NULL, "source_title" TEXT NOT NULL, "source_playlist_id" TEXT NULL, "source_is_channel" INTEGER NOT NULL CHECK ("source_is_channel" IN (0, 1)), "video_id" TEXT NOT NULL, "title" TEXT NOT NULL, "channel" TEXT NULL, "duration_seconds" INTEGER NULL, "position" INTEGER NOT NULL);
INSERT INTO pending_downloads VALUES(1,'mp4','/home/me/Vidéos','Me at the zoo',NULL,0,'jNQXAC9IVRw','Me at the zoo',NULL,NULL,1);
CREATE TABLE IF NOT EXISTS "subscriptions" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "link" TEXT NOT NULL UNIQUE, "title" TEXT NOT NULL);
PRAGMA user_version = 5;
