// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ArchiveEntriesTable extends ArchiveEntries
    with TableInfo<$ArchiveEntriesTable, ArchiveEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArchiveEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [videoId, format];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'archive_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArchiveEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {videoId, format};
  @override
  ArchiveEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArchiveEntry(
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
    );
  }

  @override
  $ArchiveEntriesTable createAlias(String alias) {
    return $ArchiveEntriesTable(attachedDatabase, alias);
  }
}

class ArchiveEntry extends DataClass implements Insertable<ArchiveEntry> {
  final String videoId;

  /// [MediaFormat.name].
  final String format;
  const ArchiveEntry({required this.videoId, required this.format});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['video_id'] = Variable<String>(videoId);
    map['format'] = Variable<String>(format);
    return map;
  }

  ArchiveEntriesCompanion toCompanion(bool nullToAbsent) {
    return ArchiveEntriesCompanion(
      videoId: Value(videoId),
      format: Value(format),
    );
  }

  factory ArchiveEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArchiveEntry(
      videoId: serializer.fromJson<String>(json['videoId']),
      format: serializer.fromJson<String>(json['format']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'videoId': serializer.toJson<String>(videoId),
      'format': serializer.toJson<String>(format),
    };
  }

  ArchiveEntry copyWith({String? videoId, String? format}) => ArchiveEntry(
    videoId: videoId ?? this.videoId,
    format: format ?? this.format,
  );
  ArchiveEntry copyWithCompanion(ArchiveEntriesCompanion data) {
    return ArchiveEntry(
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      format: data.format.present ? data.format.value : this.format,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArchiveEntry(')
          ..write('videoId: $videoId, ')
          ..write('format: $format')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(videoId, format);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArchiveEntry &&
          other.videoId == this.videoId &&
          other.format == this.format);
}

class ArchiveEntriesCompanion extends UpdateCompanion<ArchiveEntry> {
  final Value<String> videoId;
  final Value<String> format;
  final Value<int> rowid;
  const ArchiveEntriesCompanion({
    this.videoId = const Value.absent(),
    this.format = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArchiveEntriesCompanion.insert({
    required String videoId,
    required String format,
    this.rowid = const Value.absent(),
  }) : videoId = Value(videoId),
       format = Value(format);
  static Insertable<ArchiveEntry> custom({
    Expression<String>? videoId,
    Expression<String>? format,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (videoId != null) 'video_id': videoId,
      if (format != null) 'format': format,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArchiveEntriesCompanion copyWith({
    Value<String>? videoId,
    Value<String>? format,
    Value<int>? rowid,
  }) {
    return ArchiveEntriesCompanion(
      videoId: videoId ?? this.videoId,
      format: format ?? this.format,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArchiveEntriesCompanion(')
          ..write('videoId: $videoId, ')
          ..write('format: $format, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HistoryEntriesTable extends HistoryEntries
    with TableInfo<$HistoryEntriesTable, HistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HistoryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _albumMeta = const VerificationMeta('album');
  @override
  late final GeneratedColumn<String> album = GeneratedColumn<String>(
    'album',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playlistIdMeta = const VerificationMeta(
    'playlistId',
  );
  @override
  late final GeneratedColumn<String> playlistId = GeneratedColumn<String>(
    'playlist_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    videoId,
    title,
    album,
    playlistId,
    format,
    status,
    path,
    reason,
    message,
    at,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'history_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<HistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('album')) {
      context.handle(
        _albumMeta,
        album.isAcceptableOrUnknown(data['album']!, _albumMeta),
      );
    }
    if (data.containsKey('playlist_id')) {
      context.handle(
        _playlistIdMeta,
        playlistId.isAcceptableOrUnknown(data['playlist_id']!, _playlistIdMeta),
      );
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HistoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      album: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}album'],
      ),
      playlistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}playlist_id'],
      ),
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      ),
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      ),
      at: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}at'],
      )!,
    );
  }

  @override
  $HistoryEntriesTable createAlias(String alias) {
    return $HistoryEntriesTable(attachedDatabase, alias);
  }
}

class HistoryEntry extends DataClass implements Insertable<HistoryEntry> {
  final int id;
  final String videoId;
  final String title;

  /// Playlist title; null for a single video.
  final String? album;

  /// Playlist id, to fetch its new videos; null for a video or a channel.
  final String? playlistId;
  final String format;

  /// [HistoryStatus.name].
  final String status;

  /// Saved file, when it succeeded.
  final String? path;

  /// [FailureReason.name], when it failed.
  final String? reason;
  final String? message;
  final DateTime at;
  const HistoryEntry({
    required this.id,
    required this.videoId,
    required this.title,
    this.album,
    this.playlistId,
    required this.format,
    required this.status,
    this.path,
    this.reason,
    this.message,
    required this.at,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['video_id'] = Variable<String>(videoId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || album != null) {
      map['album'] = Variable<String>(album);
    }
    if (!nullToAbsent || playlistId != null) {
      map['playlist_id'] = Variable<String>(playlistId);
    }
    map['format'] = Variable<String>(format);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || path != null) {
      map['path'] = Variable<String>(path);
    }
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    if (!nullToAbsent || message != null) {
      map['message'] = Variable<String>(message);
    }
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  HistoryEntriesCompanion toCompanion(bool nullToAbsent) {
    return HistoryEntriesCompanion(
      id: Value(id),
      videoId: Value(videoId),
      title: Value(title),
      album: album == null && nullToAbsent
          ? const Value.absent()
          : Value(album),
      playlistId: playlistId == null && nullToAbsent
          ? const Value.absent()
          : Value(playlistId),
      format: Value(format),
      status: Value(status),
      path: path == null && nullToAbsent ? const Value.absent() : Value(path),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
      message: message == null && nullToAbsent
          ? const Value.absent()
          : Value(message),
      at: Value(at),
    );
  }

  factory HistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HistoryEntry(
      id: serializer.fromJson<int>(json['id']),
      videoId: serializer.fromJson<String>(json['videoId']),
      title: serializer.fromJson<String>(json['title']),
      album: serializer.fromJson<String?>(json['album']),
      playlistId: serializer.fromJson<String?>(json['playlistId']),
      format: serializer.fromJson<String>(json['format']),
      status: serializer.fromJson<String>(json['status']),
      path: serializer.fromJson<String?>(json['path']),
      reason: serializer.fromJson<String?>(json['reason']),
      message: serializer.fromJson<String?>(json['message']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'videoId': serializer.toJson<String>(videoId),
      'title': serializer.toJson<String>(title),
      'album': serializer.toJson<String?>(album),
      'playlistId': serializer.toJson<String?>(playlistId),
      'format': serializer.toJson<String>(format),
      'status': serializer.toJson<String>(status),
      'path': serializer.toJson<String?>(path),
      'reason': serializer.toJson<String?>(reason),
      'message': serializer.toJson<String?>(message),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  HistoryEntry copyWith({
    int? id,
    String? videoId,
    String? title,
    Value<String?> album = const Value.absent(),
    Value<String?> playlistId = const Value.absent(),
    String? format,
    String? status,
    Value<String?> path = const Value.absent(),
    Value<String?> reason = const Value.absent(),
    Value<String?> message = const Value.absent(),
    DateTime? at,
  }) => HistoryEntry(
    id: id ?? this.id,
    videoId: videoId ?? this.videoId,
    title: title ?? this.title,
    album: album.present ? album.value : this.album,
    playlistId: playlistId.present ? playlistId.value : this.playlistId,
    format: format ?? this.format,
    status: status ?? this.status,
    path: path.present ? path.value : this.path,
    reason: reason.present ? reason.value : this.reason,
    message: message.present ? message.value : this.message,
    at: at ?? this.at,
  );
  HistoryEntry copyWithCompanion(HistoryEntriesCompanion data) {
    return HistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      title: data.title.present ? data.title.value : this.title,
      album: data.album.present ? data.album.value : this.album,
      playlistId: data.playlistId.present
          ? data.playlistId.value
          : this.playlistId,
      format: data.format.present ? data.format.value : this.format,
      status: data.status.present ? data.status.value : this.status,
      path: data.path.present ? data.path.value : this.path,
      reason: data.reason.present ? data.reason.value : this.reason,
      message: data.message.present ? data.message.value : this.message,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HistoryEntry(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('album: $album, ')
          ..write('playlistId: $playlistId, ')
          ..write('format: $format, ')
          ..write('status: $status, ')
          ..write('path: $path, ')
          ..write('reason: $reason, ')
          ..write('message: $message, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    videoId,
    title,
    album,
    playlistId,
    format,
    status,
    path,
    reason,
    message,
    at,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HistoryEntry &&
          other.id == this.id &&
          other.videoId == this.videoId &&
          other.title == this.title &&
          other.album == this.album &&
          other.playlistId == this.playlistId &&
          other.format == this.format &&
          other.status == this.status &&
          other.path == this.path &&
          other.reason == this.reason &&
          other.message == this.message &&
          other.at == this.at);
}

class HistoryEntriesCompanion extends UpdateCompanion<HistoryEntry> {
  final Value<int> id;
  final Value<String> videoId;
  final Value<String> title;
  final Value<String?> album;
  final Value<String?> playlistId;
  final Value<String> format;
  final Value<String> status;
  final Value<String?> path;
  final Value<String?> reason;
  final Value<String?> message;
  final Value<DateTime> at;
  const HistoryEntriesCompanion({
    this.id = const Value.absent(),
    this.videoId = const Value.absent(),
    this.title = const Value.absent(),
    this.album = const Value.absent(),
    this.playlistId = const Value.absent(),
    this.format = const Value.absent(),
    this.status = const Value.absent(),
    this.path = const Value.absent(),
    this.reason = const Value.absent(),
    this.message = const Value.absent(),
    this.at = const Value.absent(),
  });
  HistoryEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String videoId,
    required String title,
    this.album = const Value.absent(),
    this.playlistId = const Value.absent(),
    required String format,
    required String status,
    this.path = const Value.absent(),
    this.reason = const Value.absent(),
    this.message = const Value.absent(),
    required DateTime at,
  }) : videoId = Value(videoId),
       title = Value(title),
       format = Value(format),
       status = Value(status),
       at = Value(at);
  static Insertable<HistoryEntry> custom({
    Expression<int>? id,
    Expression<String>? videoId,
    Expression<String>? title,
    Expression<String>? album,
    Expression<String>? playlistId,
    Expression<String>? format,
    Expression<String>? status,
    Expression<String>? path,
    Expression<String>? reason,
    Expression<String>? message,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (videoId != null) 'video_id': videoId,
      if (title != null) 'title': title,
      if (album != null) 'album': album,
      if (playlistId != null) 'playlist_id': playlistId,
      if (format != null) 'format': format,
      if (status != null) 'status': status,
      if (path != null) 'path': path,
      if (reason != null) 'reason': reason,
      if (message != null) 'message': message,
      if (at != null) 'at': at,
    });
  }

  HistoryEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? videoId,
    Value<String>? title,
    Value<String?>? album,
    Value<String?>? playlistId,
    Value<String>? format,
    Value<String>? status,
    Value<String?>? path,
    Value<String?>? reason,
    Value<String?>? message,
    Value<DateTime>? at,
  }) {
    return HistoryEntriesCompanion(
      id: id ?? this.id,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      album: album ?? this.album,
      playlistId: playlistId ?? this.playlistId,
      format: format ?? this.format,
      status: status ?? this.status,
      path: path ?? this.path,
      reason: reason ?? this.reason,
      message: message ?? this.message,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (album.present) {
      map['album'] = Variable<String>(album.value);
    }
    if (playlistId.present) {
      map['playlist_id'] = Variable<String>(playlistId.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HistoryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('album: $album, ')
          ..write('playlistId: $playlistId, ')
          ..write('format: $format, ')
          ..write('status: $status, ')
          ..write('path: $path, ')
          ..write('reason: $reason, ')
          ..write('message: $message, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingDownloadsTable extends PendingDownloads
    with TableInfo<$PendingDownloadsTable, PendingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingDownloadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
    'folder',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceTitleMeta = const VerificationMeta(
    'sourceTitle',
  );
  @override
  late final GeneratedColumn<String> sourceTitle = GeneratedColumn<String>(
    'source_title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourcePlaylistIdMeta = const VerificationMeta(
    'sourcePlaylistId',
  );
  @override
  late final GeneratedColumn<String> sourcePlaylistId = GeneratedColumn<String>(
    'source_playlist_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceIsChannelMeta = const VerificationMeta(
    'sourceIsChannel',
  );
  @override
  late final GeneratedColumn<bool> sourceIsChannel = GeneratedColumn<bool>(
    'source_is_channel',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("source_is_channel" IN (0, 1))',
    ),
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _channelMeta = const VerificationMeta(
    'channel',
  );
  @override
  late final GeneratedColumn<String> channel = GeneratedColumn<String>(
    'channel',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecondsMeta = const VerificationMeta(
    'durationSeconds',
  );
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
    'duration_seconds',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _audioQualityMeta = const VerificationMeta(
    'audioQuality',
  );
  @override
  late final GeneratedColumn<String> audioQuality = GeneratedColumn<String>(
    'audio_quality',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _videoQualityMeta = const VerificationMeta(
    'videoQuality',
  );
  @override
  late final GeneratedColumn<String> videoQuality = GeneratedColumn<String>(
    'video_quality',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    format,
    folder,
    sourceTitle,
    sourcePlaylistId,
    sourceIsChannel,
    videoId,
    title,
    channel,
    durationSeconds,
    position,
    audioQuality,
    videoQuality,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_downloads';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('folder')) {
      context.handle(
        _folderMeta,
        folder.isAcceptableOrUnknown(data['folder']!, _folderMeta),
      );
    } else if (isInserting) {
      context.missing(_folderMeta);
    }
    if (data.containsKey('source_title')) {
      context.handle(
        _sourceTitleMeta,
        sourceTitle.isAcceptableOrUnknown(
          data['source_title']!,
          _sourceTitleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceTitleMeta);
    }
    if (data.containsKey('source_playlist_id')) {
      context.handle(
        _sourcePlaylistIdMeta,
        sourcePlaylistId.isAcceptableOrUnknown(
          data['source_playlist_id']!,
          _sourcePlaylistIdMeta,
        ),
      );
    }
    if (data.containsKey('source_is_channel')) {
      context.handle(
        _sourceIsChannelMeta,
        sourceIsChannel.isAcceptableOrUnknown(
          data['source_is_channel']!,
          _sourceIsChannelMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceIsChannelMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('channel')) {
      context.handle(
        _channelMeta,
        channel.isAcceptableOrUnknown(data['channel']!, _channelMeta),
      );
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
        _durationSecondsMeta,
        durationSeconds.isAcceptableOrUnknown(
          data['duration_seconds']!,
          _durationSecondsMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('audio_quality')) {
      context.handle(
        _audioQualityMeta,
        audioQuality.isAcceptableOrUnknown(
          data['audio_quality']!,
          _audioQualityMeta,
        ),
      );
    }
    if (data.containsKey('video_quality')) {
      context.handle(
        _videoQualityMeta,
        videoQuality.isAcceptableOrUnknown(
          data['video_quality']!,
          _videoQualityMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      folder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder'],
      )!,
      sourceTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_title'],
      )!,
      sourcePlaylistId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_playlist_id'],
      ),
      sourceIsChannel: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}source_is_channel'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      channel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}channel'],
      ),
      durationSeconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_seconds'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      audioQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}audio_quality'],
      ),
      videoQuality: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_quality'],
      ),
    );
  }

  @override
  $PendingDownloadsTable createAlias(String alias) {
    return $PendingDownloadsTable(attachedDatabase, alias);
  }
}

class PendingRow extends DataClass implements Insertable<PendingRow> {
  final int id;

  /// [MediaFormat.name].
  final String format;
  final String folder;

  /// The playlist, channel or video it comes from.
  final String sourceTitle;
  final String? sourcePlaylistId;
  final bool sourceIsChannel;
  final String videoId;
  final String title;
  final String? channel;
  final int? durationSeconds;

  /// 1-based position in the source.
  final int position;

  /// [AudioQuality.name] and [VideoQuality.name]; null before v6 (default).
  final String? audioQuality;
  final String? videoQuality;
  const PendingRow({
    required this.id,
    required this.format,
    required this.folder,
    required this.sourceTitle,
    this.sourcePlaylistId,
    required this.sourceIsChannel,
    required this.videoId,
    required this.title,
    this.channel,
    this.durationSeconds,
    required this.position,
    this.audioQuality,
    this.videoQuality,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['format'] = Variable<String>(format);
    map['folder'] = Variable<String>(folder);
    map['source_title'] = Variable<String>(sourceTitle);
    if (!nullToAbsent || sourcePlaylistId != null) {
      map['source_playlist_id'] = Variable<String>(sourcePlaylistId);
    }
    map['source_is_channel'] = Variable<bool>(sourceIsChannel);
    map['video_id'] = Variable<String>(videoId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || channel != null) {
      map['channel'] = Variable<String>(channel);
    }
    if (!nullToAbsent || durationSeconds != null) {
      map['duration_seconds'] = Variable<int>(durationSeconds);
    }
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || audioQuality != null) {
      map['audio_quality'] = Variable<String>(audioQuality);
    }
    if (!nullToAbsent || videoQuality != null) {
      map['video_quality'] = Variable<String>(videoQuality);
    }
    return map;
  }

  PendingDownloadsCompanion toCompanion(bool nullToAbsent) {
    return PendingDownloadsCompanion(
      id: Value(id),
      format: Value(format),
      folder: Value(folder),
      sourceTitle: Value(sourceTitle),
      sourcePlaylistId: sourcePlaylistId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePlaylistId),
      sourceIsChannel: Value(sourceIsChannel),
      videoId: Value(videoId),
      title: Value(title),
      channel: channel == null && nullToAbsent
          ? const Value.absent()
          : Value(channel),
      durationSeconds: durationSeconds == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSeconds),
      position: Value(position),
      audioQuality: audioQuality == null && nullToAbsent
          ? const Value.absent()
          : Value(audioQuality),
      videoQuality: videoQuality == null && nullToAbsent
          ? const Value.absent()
          : Value(videoQuality),
    );
  }

  factory PendingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingRow(
      id: serializer.fromJson<int>(json['id']),
      format: serializer.fromJson<String>(json['format']),
      folder: serializer.fromJson<String>(json['folder']),
      sourceTitle: serializer.fromJson<String>(json['sourceTitle']),
      sourcePlaylistId: serializer.fromJson<String?>(json['sourcePlaylistId']),
      sourceIsChannel: serializer.fromJson<bool>(json['sourceIsChannel']),
      videoId: serializer.fromJson<String>(json['videoId']),
      title: serializer.fromJson<String>(json['title']),
      channel: serializer.fromJson<String?>(json['channel']),
      durationSeconds: serializer.fromJson<int?>(json['durationSeconds']),
      position: serializer.fromJson<int>(json['position']),
      audioQuality: serializer.fromJson<String?>(json['audioQuality']),
      videoQuality: serializer.fromJson<String?>(json['videoQuality']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'format': serializer.toJson<String>(format),
      'folder': serializer.toJson<String>(folder),
      'sourceTitle': serializer.toJson<String>(sourceTitle),
      'sourcePlaylistId': serializer.toJson<String?>(sourcePlaylistId),
      'sourceIsChannel': serializer.toJson<bool>(sourceIsChannel),
      'videoId': serializer.toJson<String>(videoId),
      'title': serializer.toJson<String>(title),
      'channel': serializer.toJson<String?>(channel),
      'durationSeconds': serializer.toJson<int?>(durationSeconds),
      'position': serializer.toJson<int>(position),
      'audioQuality': serializer.toJson<String?>(audioQuality),
      'videoQuality': serializer.toJson<String?>(videoQuality),
    };
  }

  PendingRow copyWith({
    int? id,
    String? format,
    String? folder,
    String? sourceTitle,
    Value<String?> sourcePlaylistId = const Value.absent(),
    bool? sourceIsChannel,
    String? videoId,
    String? title,
    Value<String?> channel = const Value.absent(),
    Value<int?> durationSeconds = const Value.absent(),
    int? position,
    Value<String?> audioQuality = const Value.absent(),
    Value<String?> videoQuality = const Value.absent(),
  }) => PendingRow(
    id: id ?? this.id,
    format: format ?? this.format,
    folder: folder ?? this.folder,
    sourceTitle: sourceTitle ?? this.sourceTitle,
    sourcePlaylistId: sourcePlaylistId.present
        ? sourcePlaylistId.value
        : this.sourcePlaylistId,
    sourceIsChannel: sourceIsChannel ?? this.sourceIsChannel,
    videoId: videoId ?? this.videoId,
    title: title ?? this.title,
    channel: channel.present ? channel.value : this.channel,
    durationSeconds: durationSeconds.present
        ? durationSeconds.value
        : this.durationSeconds,
    position: position ?? this.position,
    audioQuality: audioQuality.present ? audioQuality.value : this.audioQuality,
    videoQuality: videoQuality.present ? videoQuality.value : this.videoQuality,
  );
  PendingRow copyWithCompanion(PendingDownloadsCompanion data) {
    return PendingRow(
      id: data.id.present ? data.id.value : this.id,
      format: data.format.present ? data.format.value : this.format,
      folder: data.folder.present ? data.folder.value : this.folder,
      sourceTitle: data.sourceTitle.present
          ? data.sourceTitle.value
          : this.sourceTitle,
      sourcePlaylistId: data.sourcePlaylistId.present
          ? data.sourcePlaylistId.value
          : this.sourcePlaylistId,
      sourceIsChannel: data.sourceIsChannel.present
          ? data.sourceIsChannel.value
          : this.sourceIsChannel,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      title: data.title.present ? data.title.value : this.title,
      channel: data.channel.present ? data.channel.value : this.channel,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      position: data.position.present ? data.position.value : this.position,
      audioQuality: data.audioQuality.present
          ? data.audioQuality.value
          : this.audioQuality,
      videoQuality: data.videoQuality.present
          ? data.videoQuality.value
          : this.videoQuality,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingRow(')
          ..write('id: $id, ')
          ..write('format: $format, ')
          ..write('folder: $folder, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('sourcePlaylistId: $sourcePlaylistId, ')
          ..write('sourceIsChannel: $sourceIsChannel, ')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('channel: $channel, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('position: $position, ')
          ..write('audioQuality: $audioQuality, ')
          ..write('videoQuality: $videoQuality')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    format,
    folder,
    sourceTitle,
    sourcePlaylistId,
    sourceIsChannel,
    videoId,
    title,
    channel,
    durationSeconds,
    position,
    audioQuality,
    videoQuality,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingRow &&
          other.id == this.id &&
          other.format == this.format &&
          other.folder == this.folder &&
          other.sourceTitle == this.sourceTitle &&
          other.sourcePlaylistId == this.sourcePlaylistId &&
          other.sourceIsChannel == this.sourceIsChannel &&
          other.videoId == this.videoId &&
          other.title == this.title &&
          other.channel == this.channel &&
          other.durationSeconds == this.durationSeconds &&
          other.position == this.position &&
          other.audioQuality == this.audioQuality &&
          other.videoQuality == this.videoQuality);
}

class PendingDownloadsCompanion extends UpdateCompanion<PendingRow> {
  final Value<int> id;
  final Value<String> format;
  final Value<String> folder;
  final Value<String> sourceTitle;
  final Value<String?> sourcePlaylistId;
  final Value<bool> sourceIsChannel;
  final Value<String> videoId;
  final Value<String> title;
  final Value<String?> channel;
  final Value<int?> durationSeconds;
  final Value<int> position;
  final Value<String?> audioQuality;
  final Value<String?> videoQuality;
  const PendingDownloadsCompanion({
    this.id = const Value.absent(),
    this.format = const Value.absent(),
    this.folder = const Value.absent(),
    this.sourceTitle = const Value.absent(),
    this.sourcePlaylistId = const Value.absent(),
    this.sourceIsChannel = const Value.absent(),
    this.videoId = const Value.absent(),
    this.title = const Value.absent(),
    this.channel = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.position = const Value.absent(),
    this.audioQuality = const Value.absent(),
    this.videoQuality = const Value.absent(),
  });
  PendingDownloadsCompanion.insert({
    this.id = const Value.absent(),
    required String format,
    required String folder,
    required String sourceTitle,
    this.sourcePlaylistId = const Value.absent(),
    required bool sourceIsChannel,
    required String videoId,
    required String title,
    this.channel = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    required int position,
    this.audioQuality = const Value.absent(),
    this.videoQuality = const Value.absent(),
  }) : format = Value(format),
       folder = Value(folder),
       sourceTitle = Value(sourceTitle),
       sourceIsChannel = Value(sourceIsChannel),
       videoId = Value(videoId),
       title = Value(title),
       position = Value(position);
  static Insertable<PendingRow> custom({
    Expression<int>? id,
    Expression<String>? format,
    Expression<String>? folder,
    Expression<String>? sourceTitle,
    Expression<String>? sourcePlaylistId,
    Expression<bool>? sourceIsChannel,
    Expression<String>? videoId,
    Expression<String>? title,
    Expression<String>? channel,
    Expression<int>? durationSeconds,
    Expression<int>? position,
    Expression<String>? audioQuality,
    Expression<String>? videoQuality,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (format != null) 'format': format,
      if (folder != null) 'folder': folder,
      if (sourceTitle != null) 'source_title': sourceTitle,
      if (sourcePlaylistId != null) 'source_playlist_id': sourcePlaylistId,
      if (sourceIsChannel != null) 'source_is_channel': sourceIsChannel,
      if (videoId != null) 'video_id': videoId,
      if (title != null) 'title': title,
      if (channel != null) 'channel': channel,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (position != null) 'position': position,
      if (audioQuality != null) 'audio_quality': audioQuality,
      if (videoQuality != null) 'video_quality': videoQuality,
    });
  }

  PendingDownloadsCompanion copyWith({
    Value<int>? id,
    Value<String>? format,
    Value<String>? folder,
    Value<String>? sourceTitle,
    Value<String?>? sourcePlaylistId,
    Value<bool>? sourceIsChannel,
    Value<String>? videoId,
    Value<String>? title,
    Value<String?>? channel,
    Value<int?>? durationSeconds,
    Value<int>? position,
    Value<String?>? audioQuality,
    Value<String?>? videoQuality,
  }) {
    return PendingDownloadsCompanion(
      id: id ?? this.id,
      format: format ?? this.format,
      folder: folder ?? this.folder,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      sourcePlaylistId: sourcePlaylistId ?? this.sourcePlaylistId,
      sourceIsChannel: sourceIsChannel ?? this.sourceIsChannel,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      channel: channel ?? this.channel,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      position: position ?? this.position,
      audioQuality: audioQuality ?? this.audioQuality,
      videoQuality: videoQuality ?? this.videoQuality,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (sourceTitle.present) {
      map['source_title'] = Variable<String>(sourceTitle.value);
    }
    if (sourcePlaylistId.present) {
      map['source_playlist_id'] = Variable<String>(sourcePlaylistId.value);
    }
    if (sourceIsChannel.present) {
      map['source_is_channel'] = Variable<bool>(sourceIsChannel.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (channel.present) {
      map['channel'] = Variable<String>(channel.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (audioQuality.present) {
      map['audio_quality'] = Variable<String>(audioQuality.value);
    }
    if (videoQuality.present) {
      map['video_quality'] = Variable<String>(videoQuality.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingDownloadsCompanion(')
          ..write('id: $id, ')
          ..write('format: $format, ')
          ..write('folder: $folder, ')
          ..write('sourceTitle: $sourceTitle, ')
          ..write('sourcePlaylistId: $sourcePlaylistId, ')
          ..write('sourceIsChannel: $sourceIsChannel, ')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('channel: $channel, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('position: $position, ')
          ..write('audioQuality: $audioQuality, ')
          ..write('videoQuality: $videoQuality')
          ..write(')'))
        .toString();
  }
}

class $SubscriptionsTable extends Subscriptions
    with TableInfo<$SubscriptionsTable, SubscriptionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SubscriptionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _linkMeta = const VerificationMeta('link');
  @override
  late final GeneratedColumn<String> link = GeneratedColumn<String>(
    'link',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, link, title];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'subscriptions';
  @override
  VerificationContext validateIntegrity(
    Insertable<SubscriptionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('link')) {
      context.handle(
        _linkMeta,
        link.isAcceptableOrUnknown(data['link']!, _linkMeta),
      );
    } else if (isInserting) {
      context.missing(_linkMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SubscriptionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SubscriptionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      link: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
    );
  }

  @override
  $SubscriptionsTable createAlias(String alias) {
    return $SubscriptionsTable(attachedDatabase, alias);
  }
}

class SubscriptionRow extends DataClass implements Insertable<SubscriptionRow> {
  final int id;

  /// A playlist id or a channel URL, as `parseEntry` reads it.
  final String link;
  final String title;
  const SubscriptionRow({
    required this.id,
    required this.link,
    required this.title,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['link'] = Variable<String>(link);
    map['title'] = Variable<String>(title);
    return map;
  }

  SubscriptionsCompanion toCompanion(bool nullToAbsent) {
    return SubscriptionsCompanion(
      id: Value(id),
      link: Value(link),
      title: Value(title),
    );
  }

  factory SubscriptionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SubscriptionRow(
      id: serializer.fromJson<int>(json['id']),
      link: serializer.fromJson<String>(json['link']),
      title: serializer.fromJson<String>(json['title']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'link': serializer.toJson<String>(link),
      'title': serializer.toJson<String>(title),
    };
  }

  SubscriptionRow copyWith({int? id, String? link, String? title}) =>
      SubscriptionRow(
        id: id ?? this.id,
        link: link ?? this.link,
        title: title ?? this.title,
      );
  SubscriptionRow copyWithCompanion(SubscriptionsCompanion data) {
    return SubscriptionRow(
      id: data.id.present ? data.id.value : this.id,
      link: data.link.present ? data.link.value : this.link,
      title: data.title.present ? data.title.value : this.title,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionRow(')
          ..write('id: $id, ')
          ..write('link: $link, ')
          ..write('title: $title')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, link, title);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SubscriptionRow &&
          other.id == this.id &&
          other.link == this.link &&
          other.title == this.title);
}

class SubscriptionsCompanion extends UpdateCompanion<SubscriptionRow> {
  final Value<int> id;
  final Value<String> link;
  final Value<String> title;
  const SubscriptionsCompanion({
    this.id = const Value.absent(),
    this.link = const Value.absent(),
    this.title = const Value.absent(),
  });
  SubscriptionsCompanion.insert({
    this.id = const Value.absent(),
    required String link,
    required String title,
  }) : link = Value(link),
       title = Value(title);
  static Insertable<SubscriptionRow> custom({
    Expression<int>? id,
    Expression<String>? link,
    Expression<String>? title,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (link != null) 'link': link,
      if (title != null) 'title': title,
    });
  }

  SubscriptionsCompanion copyWith({
    Value<int>? id,
    Value<String>? link,
    Value<String>? title,
  }) {
    return SubscriptionsCompanion(
      id: id ?? this.id,
      link: link ?? this.link,
      title: title ?? this.title,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (link.present) {
      map['link'] = Variable<String>(link.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SubscriptionsCompanion(')
          ..write('id: $id, ')
          ..write('link: $link, ')
          ..write('title: $title')
          ..write(')'))
        .toString();
  }
}

class $UserPlaylistsTable extends UserPlaylists
    with TableInfo<$UserPlaylistsTable, UserPlaylistRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserPlaylistsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _folderMeta = const VerificationMeta('folder');
  @override
  late final GeneratedColumn<String> folder = GeneratedColumn<String>(
    'folder',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _folderLabelMeta = const VerificationMeta(
    'folderLabel',
  );
  @override
  late final GeneratedColumn<String> folderLabel = GeneratedColumn<String>(
    'folder_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    folder,
    folderLabel,
    position,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'user_playlists';
  @override
  VerificationContext validateIntegrity(
    Insertable<UserPlaylistRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('folder')) {
      context.handle(
        _folderMeta,
        folder.isAcceptableOrUnknown(data['folder']!, _folderMeta),
      );
    }
    if (data.containsKey('folder_label')) {
      context.handle(
        _folderLabelMeta,
        folderLabel.isAcceptableOrUnknown(
          data['folder_label']!,
          _folderLabelMeta,
        ),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  UserPlaylistRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return UserPlaylistRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      folder: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder'],
      ),
      folderLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}folder_label'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      ),
    );
  }

  @override
  $UserPlaylistsTable createAlias(String alias) {
    return $UserPlaylistsTable(attachedDatabase, alias);
  }
}

class UserPlaylistRow extends DataClass implements Insertable<UserPlaylistRow> {
  final int id;
  final String name;

  /// The folder it plays, read on opening; null when made by hand (v8).
  final String? folder;
  final String? folderLabel;

  /// Place chosen by the user; null until ordered: after, by creation (v9).
  final int? position;
  const UserPlaylistRow({
    required this.id,
    required this.name,
    this.folder,
    this.folderLabel,
    this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || folder != null) {
      map['folder'] = Variable<String>(folder);
    }
    if (!nullToAbsent || folderLabel != null) {
      map['folder_label'] = Variable<String>(folderLabel);
    }
    if (!nullToAbsent || position != null) {
      map['position'] = Variable<int>(position);
    }
    return map;
  }

  UserPlaylistsCompanion toCompanion(bool nullToAbsent) {
    return UserPlaylistsCompanion(
      id: Value(id),
      name: Value(name),
      folder: folder == null && nullToAbsent
          ? const Value.absent()
          : Value(folder),
      folderLabel: folderLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(folderLabel),
      position: position == null && nullToAbsent
          ? const Value.absent()
          : Value(position),
    );
  }

  factory UserPlaylistRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return UserPlaylistRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      folder: serializer.fromJson<String?>(json['folder']),
      folderLabel: serializer.fromJson<String?>(json['folderLabel']),
      position: serializer.fromJson<int?>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'folder': serializer.toJson<String?>(folder),
      'folderLabel': serializer.toJson<String?>(folderLabel),
      'position': serializer.toJson<int?>(position),
    };
  }

  UserPlaylistRow copyWith({
    int? id,
    String? name,
    Value<String?> folder = const Value.absent(),
    Value<String?> folderLabel = const Value.absent(),
    Value<int?> position = const Value.absent(),
  }) => UserPlaylistRow(
    id: id ?? this.id,
    name: name ?? this.name,
    folder: folder.present ? folder.value : this.folder,
    folderLabel: folderLabel.present ? folderLabel.value : this.folderLabel,
    position: position.present ? position.value : this.position,
  );
  UserPlaylistRow copyWithCompanion(UserPlaylistsCompanion data) {
    return UserPlaylistRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      folder: data.folder.present ? data.folder.value : this.folder,
      folderLabel: data.folderLabel.present
          ? data.folderLabel.value
          : this.folderLabel,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('UserPlaylistRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('folder: $folder, ')
          ..write('folderLabel: $folderLabel, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, folder, folderLabel, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is UserPlaylistRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.folder == this.folder &&
          other.folderLabel == this.folderLabel &&
          other.position == this.position);
}

class UserPlaylistsCompanion extends UpdateCompanion<UserPlaylistRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> folder;
  final Value<String?> folderLabel;
  final Value<int?> position;
  const UserPlaylistsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.folder = const Value.absent(),
    this.folderLabel = const Value.absent(),
    this.position = const Value.absent(),
  });
  UserPlaylistsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.folder = const Value.absent(),
    this.folderLabel = const Value.absent(),
    this.position = const Value.absent(),
  }) : name = Value(name);
  static Insertable<UserPlaylistRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? folder,
    Expression<String>? folderLabel,
    Expression<int>? position,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (folder != null) 'folder': folder,
      if (folderLabel != null) 'folder_label': folderLabel,
      if (position != null) 'position': position,
    });
  }

  UserPlaylistsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? folder,
    Value<String?>? folderLabel,
    Value<int?>? position,
  }) {
    return UserPlaylistsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      folder: folder ?? this.folder,
      folderLabel: folderLabel ?? this.folderLabel,
      position: position ?? this.position,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (folder.present) {
      map['folder'] = Variable<String>(folder.value);
    }
    if (folderLabel.present) {
      map['folder_label'] = Variable<String>(folderLabel.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UserPlaylistsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('folder: $folder, ')
          ..write('folderLabel: $folderLabel, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }
}

class $PlaylistTracksTable extends PlaylistTracks
    with TableInfo<$PlaylistTracksTable, PlaylistTrackRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlaylistTracksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _playlistMeta = const VerificationMeta(
    'playlist',
  );
  @override
  late final GeneratedColumn<int> playlist = GeneratedColumn<int>(
    'playlist',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES user_playlists (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoIdMeta = const VerificationMeta(
    'videoId',
  );
  @override
  late final GeneratedColumn<String> videoId = GeneratedColumn<String>(
    'video_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    playlist,
    position,
    videoId,
    title,
    format,
    path,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'playlist_tracks';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlaylistTrackRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('playlist')) {
      context.handle(
        _playlistMeta,
        playlist.isAcceptableOrUnknown(data['playlist']!, _playlistMeta),
      );
    } else if (isInserting) {
      context.missing(_playlistMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('video_id')) {
      context.handle(
        _videoIdMeta,
        videoId.isAcceptableOrUnknown(data['video_id']!, _videoIdMeta),
      );
    } else if (isInserting) {
      context.missing(_videoIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlaylistTrackRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlaylistTrackRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      playlist: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}playlist'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      videoId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
    );
  }

  @override
  $PlaylistTracksTable createAlias(String alias) {
    return $PlaylistTracksTable(attachedDatabase, alias);
  }
}

class PlaylistTrackRow extends DataClass
    implements Insertable<PlaylistTrackRow> {
  final int id;
  final int playlist;

  /// 0-based play order.
  final int position;
  final String videoId;
  final String title;

  /// [MediaFormat.name].
  final String format;
  final String path;
  const PlaylistTrackRow({
    required this.id,
    required this.playlist,
    required this.position,
    required this.videoId,
    required this.title,
    required this.format,
    required this.path,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['playlist'] = Variable<int>(playlist);
    map['position'] = Variable<int>(position);
    map['video_id'] = Variable<String>(videoId);
    map['title'] = Variable<String>(title);
    map['format'] = Variable<String>(format);
    map['path'] = Variable<String>(path);
    return map;
  }

  PlaylistTracksCompanion toCompanion(bool nullToAbsent) {
    return PlaylistTracksCompanion(
      id: Value(id),
      playlist: Value(playlist),
      position: Value(position),
      videoId: Value(videoId),
      title: Value(title),
      format: Value(format),
      path: Value(path),
    );
  }

  factory PlaylistTrackRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlaylistTrackRow(
      id: serializer.fromJson<int>(json['id']),
      playlist: serializer.fromJson<int>(json['playlist']),
      position: serializer.fromJson<int>(json['position']),
      videoId: serializer.fromJson<String>(json['videoId']),
      title: serializer.fromJson<String>(json['title']),
      format: serializer.fromJson<String>(json['format']),
      path: serializer.fromJson<String>(json['path']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'playlist': serializer.toJson<int>(playlist),
      'position': serializer.toJson<int>(position),
      'videoId': serializer.toJson<String>(videoId),
      'title': serializer.toJson<String>(title),
      'format': serializer.toJson<String>(format),
      'path': serializer.toJson<String>(path),
    };
  }

  PlaylistTrackRow copyWith({
    int? id,
    int? playlist,
    int? position,
    String? videoId,
    String? title,
    String? format,
    String? path,
  }) => PlaylistTrackRow(
    id: id ?? this.id,
    playlist: playlist ?? this.playlist,
    position: position ?? this.position,
    videoId: videoId ?? this.videoId,
    title: title ?? this.title,
    format: format ?? this.format,
    path: path ?? this.path,
  );
  PlaylistTrackRow copyWithCompanion(PlaylistTracksCompanion data) {
    return PlaylistTrackRow(
      id: data.id.present ? data.id.value : this.id,
      playlist: data.playlist.present ? data.playlist.value : this.playlist,
      position: data.position.present ? data.position.value : this.position,
      videoId: data.videoId.present ? data.videoId.value : this.videoId,
      title: data.title.present ? data.title.value : this.title,
      format: data.format.present ? data.format.value : this.format,
      path: data.path.present ? data.path.value : this.path,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTrackRow(')
          ..write('id: $id, ')
          ..write('playlist: $playlist, ')
          ..write('position: $position, ')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('format: $format, ')
          ..write('path: $path')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, playlist, position, videoId, title, format, path);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlaylistTrackRow &&
          other.id == this.id &&
          other.playlist == this.playlist &&
          other.position == this.position &&
          other.videoId == this.videoId &&
          other.title == this.title &&
          other.format == this.format &&
          other.path == this.path);
}

class PlaylistTracksCompanion extends UpdateCompanion<PlaylistTrackRow> {
  final Value<int> id;
  final Value<int> playlist;
  final Value<int> position;
  final Value<String> videoId;
  final Value<String> title;
  final Value<String> format;
  final Value<String> path;
  const PlaylistTracksCompanion({
    this.id = const Value.absent(),
    this.playlist = const Value.absent(),
    this.position = const Value.absent(),
    this.videoId = const Value.absent(),
    this.title = const Value.absent(),
    this.format = const Value.absent(),
    this.path = const Value.absent(),
  });
  PlaylistTracksCompanion.insert({
    this.id = const Value.absent(),
    required int playlist,
    required int position,
    required String videoId,
    required String title,
    required String format,
    required String path,
  }) : playlist = Value(playlist),
       position = Value(position),
       videoId = Value(videoId),
       title = Value(title),
       format = Value(format),
       path = Value(path);
  static Insertable<PlaylistTrackRow> custom({
    Expression<int>? id,
    Expression<int>? playlist,
    Expression<int>? position,
    Expression<String>? videoId,
    Expression<String>? title,
    Expression<String>? format,
    Expression<String>? path,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (playlist != null) 'playlist': playlist,
      if (position != null) 'position': position,
      if (videoId != null) 'video_id': videoId,
      if (title != null) 'title': title,
      if (format != null) 'format': format,
      if (path != null) 'path': path,
    });
  }

  PlaylistTracksCompanion copyWith({
    Value<int>? id,
    Value<int>? playlist,
    Value<int>? position,
    Value<String>? videoId,
    Value<String>? title,
    Value<String>? format,
    Value<String>? path,
  }) {
    return PlaylistTracksCompanion(
      id: id ?? this.id,
      playlist: playlist ?? this.playlist,
      position: position ?? this.position,
      videoId: videoId ?? this.videoId,
      title: title ?? this.title,
      format: format ?? this.format,
      path: path ?? this.path,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (playlist.present) {
      map['playlist'] = Variable<int>(playlist.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (videoId.present) {
      map['video_id'] = Variable<String>(videoId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlaylistTracksCompanion(')
          ..write('id: $id, ')
          ..write('playlist: $playlist, ')
          ..write('position: $position, ')
          ..write('videoId: $videoId, ')
          ..write('title: $title, ')
          ..write('format: $format, ')
          ..write('path: $path')
          ..write(')'))
        .toString();
  }
}

abstract class _$Ka7Database extends GeneratedDatabase {
  _$Ka7Database(QueryExecutor e) : super(e);
  $Ka7DatabaseManager get managers => $Ka7DatabaseManager(this);
  late final $ArchiveEntriesTable archiveEntries = $ArchiveEntriesTable(this);
  late final $HistoryEntriesTable historyEntries = $HistoryEntriesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $PendingDownloadsTable pendingDownloads = $PendingDownloadsTable(
    this,
  );
  late final $SubscriptionsTable subscriptions = $SubscriptionsTable(this);
  late final $UserPlaylistsTable userPlaylists = $UserPlaylistsTable(this);
  late final $PlaylistTracksTable playlistTracks = $PlaylistTracksTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    archiveEntries,
    historyEntries,
    settings,
    pendingDownloads,
    subscriptions,
    userPlaylists,
    playlistTracks,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'user_playlists',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('playlist_tracks', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ArchiveEntriesTableCreateCompanionBuilder =
    ArchiveEntriesCompanion Function({
      required String videoId,
      required String format,
      Value<int> rowid,
    });
typedef $$ArchiveEntriesTableUpdateCompanionBuilder =
    ArchiveEntriesCompanion Function({
      Value<String> videoId,
      Value<String> format,
      Value<int> rowid,
    });

class $$ArchiveEntriesTableFilterComposer
    extends Composer<_$Ka7Database, $ArchiveEntriesTable> {
  $$ArchiveEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArchiveEntriesTableOrderingComposer
    extends Composer<_$Ka7Database, $ArchiveEntriesTable> {
  $$ArchiveEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArchiveEntriesTableAnnotationComposer
    extends Composer<_$Ka7Database, $ArchiveEntriesTable> {
  $$ArchiveEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);
}

class $$ArchiveEntriesTableTableManager
    extends
        RootTableManager<
          _$Ka7Database,
          $ArchiveEntriesTable,
          ArchiveEntry,
          $$ArchiveEntriesTableFilterComposer,
          $$ArchiveEntriesTableOrderingComposer,
          $$ArchiveEntriesTableAnnotationComposer,
          $$ArchiveEntriesTableCreateCompanionBuilder,
          $$ArchiveEntriesTableUpdateCompanionBuilder,
          (
            ArchiveEntry,
            BaseReferences<_$Ka7Database, $ArchiveEntriesTable, ArchiveEntry>,
          ),
          ArchiveEntry,
          PrefetchHooks Function()
        > {
  $$ArchiveEntriesTableTableManager(
    _$Ka7Database db,
    $ArchiveEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArchiveEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArchiveEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArchiveEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> videoId = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArchiveEntriesCompanion(
                videoId: videoId,
                format: format,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String videoId,
                required String format,
                Value<int> rowid = const Value.absent(),
              }) => ArchiveEntriesCompanion.insert(
                videoId: videoId,
                format: format,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArchiveEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$Ka7Database,
      $ArchiveEntriesTable,
      ArchiveEntry,
      $$ArchiveEntriesTableFilterComposer,
      $$ArchiveEntriesTableOrderingComposer,
      $$ArchiveEntriesTableAnnotationComposer,
      $$ArchiveEntriesTableCreateCompanionBuilder,
      $$ArchiveEntriesTableUpdateCompanionBuilder,
      (
        ArchiveEntry,
        BaseReferences<_$Ka7Database, $ArchiveEntriesTable, ArchiveEntry>,
      ),
      ArchiveEntry,
      PrefetchHooks Function()
    >;
typedef $$HistoryEntriesTableCreateCompanionBuilder =
    HistoryEntriesCompanion Function({
      Value<int> id,
      required String videoId,
      required String title,
      Value<String?> album,
      Value<String?> playlistId,
      required String format,
      required String status,
      Value<String?> path,
      Value<String?> reason,
      Value<String?> message,
      required DateTime at,
    });
typedef $$HistoryEntriesTableUpdateCompanionBuilder =
    HistoryEntriesCompanion Function({
      Value<int> id,
      Value<String> videoId,
      Value<String> title,
      Value<String?> album,
      Value<String?> playlistId,
      Value<String> format,
      Value<String> status,
      Value<String?> path,
      Value<String?> reason,
      Value<String?> message,
      Value<DateTime> at,
    });

class $$HistoryEntriesTableFilterComposer
    extends Composer<_$Ka7Database, $HistoryEntriesTable> {
  $$HistoryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HistoryEntriesTableOrderingComposer
    extends Composer<_$Ka7Database, $HistoryEntriesTable> {
  $$HistoryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get album => $composableBuilder(
    column: $table.album,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get at => $composableBuilder(
    column: $table.at,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HistoryEntriesTableAnnotationComposer
    extends Composer<_$Ka7Database, $HistoryEntriesTable> {
  $$HistoryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get album =>
      $composableBuilder(column: $table.album, builder: (column) => column);

  GeneratedColumn<String> get playlistId => $composableBuilder(
    column: $table.playlistId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$HistoryEntriesTableTableManager
    extends
        RootTableManager<
          _$Ka7Database,
          $HistoryEntriesTable,
          HistoryEntry,
          $$HistoryEntriesTableFilterComposer,
          $$HistoryEntriesTableOrderingComposer,
          $$HistoryEntriesTableAnnotationComposer,
          $$HistoryEntriesTableCreateCompanionBuilder,
          $$HistoryEntriesTableUpdateCompanionBuilder,
          (
            HistoryEntry,
            BaseReferences<_$Ka7Database, $HistoryEntriesTable, HistoryEntry>,
          ),
          HistoryEntry,
          PrefetchHooks Function()
        > {
  $$HistoryEntriesTableTableManager(
    _$Ka7Database db,
    $HistoryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HistoryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HistoryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HistoryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> album = const Value.absent(),
                Value<String?> playlistId = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> path = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String?> message = const Value.absent(),
                Value<DateTime> at = const Value.absent(),
              }) => HistoryEntriesCompanion(
                id: id,
                videoId: videoId,
                title: title,
                album: album,
                playlistId: playlistId,
                format: format,
                status: status,
                path: path,
                reason: reason,
                message: message,
                at: at,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String videoId,
                required String title,
                Value<String?> album = const Value.absent(),
                Value<String?> playlistId = const Value.absent(),
                required String format,
                required String status,
                Value<String?> path = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<String?> message = const Value.absent(),
                required DateTime at,
              }) => HistoryEntriesCompanion.insert(
                id: id,
                videoId: videoId,
                title: title,
                album: album,
                playlistId: playlistId,
                format: format,
                status: status,
                path: path,
                reason: reason,
                message: message,
                at: at,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HistoryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$Ka7Database,
      $HistoryEntriesTable,
      HistoryEntry,
      $$HistoryEntriesTableFilterComposer,
      $$HistoryEntriesTableOrderingComposer,
      $$HistoryEntriesTableAnnotationComposer,
      $$HistoryEntriesTableCreateCompanionBuilder,
      $$HistoryEntriesTableUpdateCompanionBuilder,
      (
        HistoryEntry,
        BaseReferences<_$Ka7Database, $HistoryEntriesTable, HistoryEntry>,
      ),
      HistoryEntry,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder =
    SettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SettingsTableUpdateCompanionBuilder =
    SettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SettingsTableFilterComposer
    extends Composer<_$Ka7Database, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$Ka7Database, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$Ka7Database, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$Ka7Database,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$Ka7Database, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$Ka7Database db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$Ka7Database,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$Ka7Database, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$PendingDownloadsTableCreateCompanionBuilder =
    PendingDownloadsCompanion Function({
      Value<int> id,
      required String format,
      required String folder,
      required String sourceTitle,
      Value<String?> sourcePlaylistId,
      required bool sourceIsChannel,
      required String videoId,
      required String title,
      Value<String?> channel,
      Value<int?> durationSeconds,
      required int position,
      Value<String?> audioQuality,
      Value<String?> videoQuality,
    });
typedef $$PendingDownloadsTableUpdateCompanionBuilder =
    PendingDownloadsCompanion Function({
      Value<int> id,
      Value<String> format,
      Value<String> folder,
      Value<String> sourceTitle,
      Value<String?> sourcePlaylistId,
      Value<bool> sourceIsChannel,
      Value<String> videoId,
      Value<String> title,
      Value<String?> channel,
      Value<int?> durationSeconds,
      Value<int> position,
      Value<String?> audioQuality,
      Value<String?> videoQuality,
    });

class $$PendingDownloadsTableFilterComposer
    extends Composer<_$Ka7Database, $PendingDownloadsTable> {
  $$PendingDownloadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourcePlaylistId => $composableBuilder(
    column: $table.sourcePlaylistId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get sourceIsChannel => $composableBuilder(
    column: $table.sourceIsChannel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get audioQuality => $composableBuilder(
    column: $table.audioQuality,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoQuality => $composableBuilder(
    column: $table.videoQuality,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingDownloadsTableOrderingComposer
    extends Composer<_$Ka7Database, $PendingDownloadsTable> {
  $$PendingDownloadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourcePlaylistId => $composableBuilder(
    column: $table.sourcePlaylistId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get sourceIsChannel => $composableBuilder(
    column: $table.sourceIsChannel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get channel => $composableBuilder(
    column: $table.channel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get audioQuality => $composableBuilder(
    column: $table.audioQuality,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoQuality => $composableBuilder(
    column: $table.videoQuality,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingDownloadsTableAnnotationComposer
    extends Composer<_$Ka7Database, $PendingDownloadsTable> {
  $$PendingDownloadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<String> get sourceTitle => $composableBuilder(
    column: $table.sourceTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourcePlaylistId => $composableBuilder(
    column: $table.sourcePlaylistId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get sourceIsChannel => $composableBuilder(
    column: $table.sourceIsChannel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get channel =>
      $composableBuilder(column: $table.channel, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
    column: $table.durationSeconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get audioQuality => $composableBuilder(
    column: $table.audioQuality,
    builder: (column) => column,
  );

  GeneratedColumn<String> get videoQuality => $composableBuilder(
    column: $table.videoQuality,
    builder: (column) => column,
  );
}

class $$PendingDownloadsTableTableManager
    extends
        RootTableManager<
          _$Ka7Database,
          $PendingDownloadsTable,
          PendingRow,
          $$PendingDownloadsTableFilterComposer,
          $$PendingDownloadsTableOrderingComposer,
          $$PendingDownloadsTableAnnotationComposer,
          $$PendingDownloadsTableCreateCompanionBuilder,
          $$PendingDownloadsTableUpdateCompanionBuilder,
          (
            PendingRow,
            BaseReferences<_$Ka7Database, $PendingDownloadsTable, PendingRow>,
          ),
          PendingRow,
          PrefetchHooks Function()
        > {
  $$PendingDownloadsTableTableManager(
    _$Ka7Database db,
    $PendingDownloadsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingDownloadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingDownloadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingDownloadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> folder = const Value.absent(),
                Value<String> sourceTitle = const Value.absent(),
                Value<String?> sourcePlaylistId = const Value.absent(),
                Value<bool> sourceIsChannel = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> channel = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> audioQuality = const Value.absent(),
                Value<String?> videoQuality = const Value.absent(),
              }) => PendingDownloadsCompanion(
                id: id,
                format: format,
                folder: folder,
                sourceTitle: sourceTitle,
                sourcePlaylistId: sourcePlaylistId,
                sourceIsChannel: sourceIsChannel,
                videoId: videoId,
                title: title,
                channel: channel,
                durationSeconds: durationSeconds,
                position: position,
                audioQuality: audioQuality,
                videoQuality: videoQuality,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String format,
                required String folder,
                required String sourceTitle,
                Value<String?> sourcePlaylistId = const Value.absent(),
                required bool sourceIsChannel,
                required String videoId,
                required String title,
                Value<String?> channel = const Value.absent(),
                Value<int?> durationSeconds = const Value.absent(),
                required int position,
                Value<String?> audioQuality = const Value.absent(),
                Value<String?> videoQuality = const Value.absent(),
              }) => PendingDownloadsCompanion.insert(
                id: id,
                format: format,
                folder: folder,
                sourceTitle: sourceTitle,
                sourcePlaylistId: sourcePlaylistId,
                sourceIsChannel: sourceIsChannel,
                videoId: videoId,
                title: title,
                channel: channel,
                durationSeconds: durationSeconds,
                position: position,
                audioQuality: audioQuality,
                videoQuality: videoQuality,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingDownloadsTableProcessedTableManager =
    ProcessedTableManager<
      _$Ka7Database,
      $PendingDownloadsTable,
      PendingRow,
      $$PendingDownloadsTableFilterComposer,
      $$PendingDownloadsTableOrderingComposer,
      $$PendingDownloadsTableAnnotationComposer,
      $$PendingDownloadsTableCreateCompanionBuilder,
      $$PendingDownloadsTableUpdateCompanionBuilder,
      (
        PendingRow,
        BaseReferences<_$Ka7Database, $PendingDownloadsTable, PendingRow>,
      ),
      PendingRow,
      PrefetchHooks Function()
    >;
typedef $$SubscriptionsTableCreateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<int> id,
      required String link,
      required String title,
    });
typedef $$SubscriptionsTableUpdateCompanionBuilder =
    SubscriptionsCompanion Function({
      Value<int> id,
      Value<String> link,
      Value<String> title,
    });

class $$SubscriptionsTableFilterComposer
    extends Composer<_$Ka7Database, $SubscriptionsTable> {
  $$SubscriptionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SubscriptionsTableOrderingComposer
    extends Composer<_$Ka7Database, $SubscriptionsTable> {
  $$SubscriptionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get link => $composableBuilder(
    column: $table.link,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SubscriptionsTableAnnotationComposer
    extends Composer<_$Ka7Database, $SubscriptionsTable> {
  $$SubscriptionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get link =>
      $composableBuilder(column: $table.link, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);
}

class $$SubscriptionsTableTableManager
    extends
        RootTableManager<
          _$Ka7Database,
          $SubscriptionsTable,
          SubscriptionRow,
          $$SubscriptionsTableFilterComposer,
          $$SubscriptionsTableOrderingComposer,
          $$SubscriptionsTableAnnotationComposer,
          $$SubscriptionsTableCreateCompanionBuilder,
          $$SubscriptionsTableUpdateCompanionBuilder,
          (
            SubscriptionRow,
            BaseReferences<_$Ka7Database, $SubscriptionsTable, SubscriptionRow>,
          ),
          SubscriptionRow,
          PrefetchHooks Function()
        > {
  $$SubscriptionsTableTableManager(_$Ka7Database db, $SubscriptionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SubscriptionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SubscriptionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SubscriptionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> link = const Value.absent(),
                Value<String> title = const Value.absent(),
              }) => SubscriptionsCompanion(id: id, link: link, title: title),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String link,
                required String title,
              }) => SubscriptionsCompanion.insert(
                id: id,
                link: link,
                title: title,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SubscriptionsTableProcessedTableManager =
    ProcessedTableManager<
      _$Ka7Database,
      $SubscriptionsTable,
      SubscriptionRow,
      $$SubscriptionsTableFilterComposer,
      $$SubscriptionsTableOrderingComposer,
      $$SubscriptionsTableAnnotationComposer,
      $$SubscriptionsTableCreateCompanionBuilder,
      $$SubscriptionsTableUpdateCompanionBuilder,
      (
        SubscriptionRow,
        BaseReferences<_$Ka7Database, $SubscriptionsTable, SubscriptionRow>,
      ),
      SubscriptionRow,
      PrefetchHooks Function()
    >;
typedef $$UserPlaylistsTableCreateCompanionBuilder =
    UserPlaylistsCompanion Function({
      Value<int> id,
      required String name,
      Value<String?> folder,
      Value<String?> folderLabel,
      Value<int?> position,
    });
typedef $$UserPlaylistsTableUpdateCompanionBuilder =
    UserPlaylistsCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<String?> folder,
      Value<String?> folderLabel,
      Value<int?> position,
    });

final class $$UserPlaylistsTableReferences
    extends
        BaseReferences<_$Ka7Database, $UserPlaylistsTable, UserPlaylistRow> {
  $$UserPlaylistsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$PlaylistTracksTable, List<PlaylistTrackRow>>
  _playlistTracksRefsTable(_$Ka7Database db) => MultiTypedResultKey.fromTable(
    db.playlistTracks,
    aliasName: 'user_playlists__id__playlist_tracks__playlist',
  );

  $$PlaylistTracksTableProcessedTableManager get playlistTracksRefs {
    final manager = $$PlaylistTracksTableTableManager(
      $_db,
      $_db.playlistTracks,
    ).filter((f) => f.playlist.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_playlistTracksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UserPlaylistsTableFilterComposer
    extends Composer<_$Ka7Database, $UserPlaylistsTable> {
  $$UserPlaylistsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get folderLabel => $composableBuilder(
    column: $table.folderLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> playlistTracksRefs(
    Expression<bool> Function($$PlaylistTracksTableFilterComposer f) f,
  ) {
    final $$PlaylistTracksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistTracks,
      getReferencedColumn: (t) => t.playlist,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistTracksTableFilterComposer(
            $db: $db,
            $table: $db.playlistTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserPlaylistsTableOrderingComposer
    extends Composer<_$Ka7Database, $UserPlaylistsTable> {
  $$UserPlaylistsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folder => $composableBuilder(
    column: $table.folder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get folderLabel => $composableBuilder(
    column: $table.folderLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UserPlaylistsTableAnnotationComposer
    extends Composer<_$Ka7Database, $UserPlaylistsTable> {
  $$UserPlaylistsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get folder =>
      $composableBuilder(column: $table.folder, builder: (column) => column);

  GeneratedColumn<String> get folderLabel => $composableBuilder(
    column: $table.folderLabel,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  Expression<T> playlistTracksRefs<T extends Object>(
    Expression<T> Function($$PlaylistTracksTableAnnotationComposer a) f,
  ) {
    final $$PlaylistTracksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.playlistTracks,
      getReferencedColumn: (t) => t.playlist,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PlaylistTracksTableAnnotationComposer(
            $db: $db,
            $table: $db.playlistTracks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserPlaylistsTableTableManager
    extends
        RootTableManager<
          _$Ka7Database,
          $UserPlaylistsTable,
          UserPlaylistRow,
          $$UserPlaylistsTableFilterComposer,
          $$UserPlaylistsTableOrderingComposer,
          $$UserPlaylistsTableAnnotationComposer,
          $$UserPlaylistsTableCreateCompanionBuilder,
          $$UserPlaylistsTableUpdateCompanionBuilder,
          (UserPlaylistRow, $$UserPlaylistsTableReferences),
          UserPlaylistRow,
          PrefetchHooks Function({bool playlistTracksRefs})
        > {
  $$UserPlaylistsTableTableManager(_$Ka7Database db, $UserPlaylistsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UserPlaylistsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UserPlaylistsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UserPlaylistsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> folder = const Value.absent(),
                Value<String?> folderLabel = const Value.absent(),
                Value<int?> position = const Value.absent(),
              }) => UserPlaylistsCompanion(
                id: id,
                name: name,
                folder: folder,
                folderLabel: folderLabel,
                position: position,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> folder = const Value.absent(),
                Value<String?> folderLabel = const Value.absent(),
                Value<int?> position = const Value.absent(),
              }) => UserPlaylistsCompanion.insert(
                id: id,
                name: name,
                folder: folder,
                folderLabel: folderLabel,
                position: position,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$UserPlaylistsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlistTracksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (playlistTracksRefs) db.playlistTracks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (playlistTracksRefs)
                    await $_getPrefetchedData<
                      UserPlaylistRow,
                      $UserPlaylistsTable,
                      PlaylistTrackRow
                    >(
                      currentTable: table,
                      referencedTable: $$UserPlaylistsTableReferences
                          ._playlistTracksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$UserPlaylistsTableReferences(
                            db,
                            table,
                            p0,
                          ).playlistTracksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.playlist == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$UserPlaylistsTableProcessedTableManager =
    ProcessedTableManager<
      _$Ka7Database,
      $UserPlaylistsTable,
      UserPlaylistRow,
      $$UserPlaylistsTableFilterComposer,
      $$UserPlaylistsTableOrderingComposer,
      $$UserPlaylistsTableAnnotationComposer,
      $$UserPlaylistsTableCreateCompanionBuilder,
      $$UserPlaylistsTableUpdateCompanionBuilder,
      (UserPlaylistRow, $$UserPlaylistsTableReferences),
      UserPlaylistRow,
      PrefetchHooks Function({bool playlistTracksRefs})
    >;
typedef $$PlaylistTracksTableCreateCompanionBuilder =
    PlaylistTracksCompanion Function({
      Value<int> id,
      required int playlist,
      required int position,
      required String videoId,
      required String title,
      required String format,
      required String path,
    });
typedef $$PlaylistTracksTableUpdateCompanionBuilder =
    PlaylistTracksCompanion Function({
      Value<int> id,
      Value<int> playlist,
      Value<int> position,
      Value<String> videoId,
      Value<String> title,
      Value<String> format,
      Value<String> path,
    });

final class $$PlaylistTracksTableReferences
    extends
        BaseReferences<_$Ka7Database, $PlaylistTracksTable, PlaylistTrackRow> {
  $$PlaylistTracksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $UserPlaylistsTable _playlistTable(_$Ka7Database db) => db
      .userPlaylists
      .createAlias('playlist_tracks__playlist__user_playlists__id');

  $$UserPlaylistsTableProcessedTableManager get playlist {
    final $_column = $_itemColumn<int>('playlist')!;

    final manager = $$UserPlaylistsTableTableManager(
      $_db,
      $_db.userPlaylists,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_playlistTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PlaylistTracksTableFilterComposer
    extends Composer<_$Ka7Database, $PlaylistTracksTable> {
  $$PlaylistTracksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  $$UserPlaylistsTableFilterComposer get playlist {
    final $$UserPlaylistsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlist,
      referencedTable: $db.userPlaylists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPlaylistsTableFilterComposer(
            $db: $db,
            $table: $db.userPlaylists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTracksTableOrderingComposer
    extends Composer<_$Ka7Database, $PlaylistTracksTable> {
  $$PlaylistTracksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoId => $composableBuilder(
    column: $table.videoId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  $$UserPlaylistsTableOrderingComposer get playlist {
    final $$UserPlaylistsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlist,
      referencedTable: $db.userPlaylists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPlaylistsTableOrderingComposer(
            $db: $db,
            $table: $db.userPlaylists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTracksTableAnnotationComposer
    extends Composer<_$Ka7Database, $PlaylistTracksTable> {
  $$PlaylistTracksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get videoId =>
      $composableBuilder(column: $table.videoId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  $$UserPlaylistsTableAnnotationComposer get playlist {
    final $$UserPlaylistsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.playlist,
      referencedTable: $db.userPlaylists,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$UserPlaylistsTableAnnotationComposer(
            $db: $db,
            $table: $db.userPlaylists,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PlaylistTracksTableTableManager
    extends
        RootTableManager<
          _$Ka7Database,
          $PlaylistTracksTable,
          PlaylistTrackRow,
          $$PlaylistTracksTableFilterComposer,
          $$PlaylistTracksTableOrderingComposer,
          $$PlaylistTracksTableAnnotationComposer,
          $$PlaylistTracksTableCreateCompanionBuilder,
          $$PlaylistTracksTableUpdateCompanionBuilder,
          (PlaylistTrackRow, $$PlaylistTracksTableReferences),
          PlaylistTrackRow,
          PrefetchHooks Function({bool playlist})
        > {
  $$PlaylistTracksTableTableManager(
    _$Ka7Database db,
    $PlaylistTracksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PlaylistTracksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PlaylistTracksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PlaylistTracksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> playlist = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> videoId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> path = const Value.absent(),
              }) => PlaylistTracksCompanion(
                id: id,
                playlist: playlist,
                position: position,
                videoId: videoId,
                title: title,
                format: format,
                path: path,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int playlist,
                required int position,
                required String videoId,
                required String title,
                required String format,
                required String path,
              }) => PlaylistTracksCompanion.insert(
                id: id,
                playlist: playlist,
                position: position,
                videoId: videoId,
                title: title,
                format: format,
                path: path,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$PlaylistTracksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({playlist = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (playlist) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.playlist,
                                referencedTable: $$PlaylistTracksTableReferences
                                    ._playlistTable(db),
                                referencedColumn:
                                    $$PlaylistTracksTableReferences
                                        ._playlistTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PlaylistTracksTableProcessedTableManager =
    ProcessedTableManager<
      _$Ka7Database,
      $PlaylistTracksTable,
      PlaylistTrackRow,
      $$PlaylistTracksTableFilterComposer,
      $$PlaylistTracksTableOrderingComposer,
      $$PlaylistTracksTableAnnotationComposer,
      $$PlaylistTracksTableCreateCompanionBuilder,
      $$PlaylistTracksTableUpdateCompanionBuilder,
      (PlaylistTrackRow, $$PlaylistTracksTableReferences),
      PlaylistTrackRow,
      PrefetchHooks Function({bool playlist})
    >;

class $Ka7DatabaseManager {
  final _$Ka7Database _db;
  $Ka7DatabaseManager(this._db);
  $$ArchiveEntriesTableTableManager get archiveEntries =>
      $$ArchiveEntriesTableTableManager(_db, _db.archiveEntries);
  $$HistoryEntriesTableTableManager get historyEntries =>
      $$HistoryEntriesTableTableManager(_db, _db.historyEntries);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$PendingDownloadsTableTableManager get pendingDownloads =>
      $$PendingDownloadsTableTableManager(_db, _db.pendingDownloads);
  $$SubscriptionsTableTableManager get subscriptions =>
      $$SubscriptionsTableTableManager(_db, _db.subscriptions);
  $$UserPlaylistsTableTableManager get userPlaylists =>
      $$UserPlaylistsTableTableManager(_db, _db.userPlaylists);
  $$PlaylistTracksTableTableManager get playlistTracks =>
      $$PlaylistTracksTableTableManager(_db, _db.playlistTracks);
}
