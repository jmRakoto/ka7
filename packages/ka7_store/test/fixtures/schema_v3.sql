-- Ka7 store schema v3, as written by ka7_store before playlist ids in the history.
CREATE TABLE "archive_entries" ("video_id" TEXT NOT NULL, "format" TEXT NOT NULL, PRIMARY KEY ("video_id", "format"));
CREATE TABLE "history_entries" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "video_id" TEXT NOT NULL, "title" TEXT NOT NULL, "album" TEXT NULL, "format" TEXT NOT NULL, "status" TEXT NOT NULL, "path" TEXT NULL, "reason" TEXT NULL, "message" TEXT NULL, "at" INTEGER NOT NULL);
CREATE TABLE "settings" ("key" TEXT NOT NULL, "value" TEXT NOT NULL, PRIMARY KEY ("key"));
CREATE TABLE "pending_downloads" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "format" TEXT NOT NULL, "folder" TEXT NOT NULL, "source_title" TEXT NOT NULL, "source_playlist_id" TEXT NULL, "source_is_channel" INTEGER NOT NULL CHECK ("source_is_channel" IN (0, 1)), "video_id" TEXT NOT NULL, "title" TEXT NOT NULL, "channel" TEXT NULL, "duration_seconds" INTEGER NULL, "position" INTEGER NOT NULL);
INSERT INTO archive_entries (video_id,format) VALUES ('jNQXAC9IVRw','mp3');
INSERT INTO history_entries (id,video_id,title,album,format,status,path,reason,message,at) VALUES (1,'jNQXAC9IVRw','Me at the zoo','Mahaleo','mp3','succeeded','/m/Mahaleo/01 - Me at the zoo.mp3',NULL,NULL,1793318400);
PRAGMA user_version = 3;
