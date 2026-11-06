-- Ka7 store schema v6, as written by ka7_store before user playlists.
CREATE TABLE IF NOT EXISTS "archive_entries" ("video_id" TEXT NOT NULL, "format" TEXT NOT NULL, PRIMARY KEY ("video_id", "format"));
INSERT INTO archive_entries VALUES('jNQXAC9IVRw','mp3');
CREATE TABLE IF NOT EXISTS "history_entries" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "video_id" TEXT NOT NULL, "title" TEXT NOT NULL, "album" TEXT NULL, "format" TEXT NOT NULL, "status" TEXT NOT NULL, "path" TEXT NULL, "reason" TEXT NULL, "message" TEXT NULL, "at" INTEGER NOT NULL, "playlist_id" TEXT NULL);
INSERT INTO history_entries VALUES(1,'jNQXAC9IVRw','Me at the zoo',NULL,'mp3','succeeded','/home/me/Musique/Ka7/Me at the zoo.mp3',NULL,NULL,1793000000,NULL);
CREATE TABLE IF NOT EXISTS "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"));
CREATE TABLE IF NOT EXISTS "pending_downloads" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "format" TEXT NOT NULL, "folder" TEXT NOT NULL, "source_title" TEXT NOT NULL, "source_playlist_id" TEXT NULL, "source_is_channel" INTEGER NOT NULL CHECK ("source_is_channel" IN (0, 1)), "video_id" TEXT NOT NULL, "title" TEXT NOT NULL, "channel" TEXT NULL, "duration_seconds" INTEGER NULL, "position" INTEGER NOT NULL, "audio_quality" TEXT NULL, "video_quality" TEXT NULL);
CREATE TABLE IF NOT EXISTS "subscriptions" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "link" TEXT NOT NULL UNIQUE, "title" TEXT NOT NULL);
PRAGMA user_version = 6;
