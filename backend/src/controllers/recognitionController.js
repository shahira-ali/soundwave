const db = require('../config/database');
const { recognizeSong } = require('../services/recognitionService');

// POST /api/recognize
const recognize = async (req, res, next) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: 'Audio file is required' });
    }

    const audioBuffer = req.file.buffer;
    const mimeType = req.file.mimetype;
    const { latitude, longitude, location_name } = req.body;

    // Call music recognition service
    const result = await recognizeSong(audioBuffer, mimeType);

    if (!result.found) {
      return res.status(404).json({
        success: false,
        message: 'Song not recognized. Try recording a clearer sample.',
      });
    }

    // Upsert song into our DB (cache it)
    let song;
    if (result.song.acrid) {
      const existing = await db.query('SELECT * FROM songs WHERE acrid = $1', [result.song.acrid]);
      if (existing.rows.length > 0) {
        song = existing.rows[0];
      }
    }

    if (!song) {
      const insertResult = await db.query(
        `INSERT INTO songs
           (title, artist, album, release_date, genre, cover_url, preview_url,
            spotify_url, apple_music_url, youtube_url, isrc, acrid)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
         ON CONFLICT (acrid) DO UPDATE SET
           cover_url = EXCLUDED.cover_url,
           preview_url = EXCLUDED.preview_url
         RETURNING *`,
        [
          result.song.title,
          result.song.artist,
          result.song.album,
          result.song.release_date,
          result.song.genre,
          result.song.cover_url,
          result.song.preview_url,
          result.song.spotify_url,
          result.song.apple_music_url,
          result.song.youtube_url,
          result.song.isrc,
          result.song.acrid,
        ]
      );
      song = insertResult.rows[0];
    }

    // Save to recognition history if user is logged in
    if (req.user) {
      await db.query(
        `INSERT INTO recognitions (user_id, song_id, latitude, longitude, location_name)
         VALUES ($1, $2, $3, $4, $5)`,
        [
          req.user.id,
          song.id,
          latitude ? parseFloat(latitude) : null,
          longitude ? parseFloat(longitude) : null,
          location_name || null,
        ]
      );
    }

    res.json({
      success: true,
      data: {
        song,
        score: result.score,
      },
    });
  } catch (err) {
    next(err);
  }
};

// GET /api/history
const getHistory = async (req, res, next) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const offset = (page - 1) * limit;

    const result = await db.query(
      `SELECT r.id, r.recognized_at, r.latitude, r.longitude, r.location_name,
              s.id as song_id, s.title, s.artist, s.album, s.genre,
              s.cover_url, s.preview_url, s.spotify_url, s.apple_music_url
       FROM recognitions r
       JOIN songs s ON r.song_id = s.id
       WHERE r.user_id = $1
       ORDER BY r.recognized_at DESC
       LIMIT $2 OFFSET $3`,
      [req.user.id, limit, offset]
    );

    const countResult = await db.query(
      'SELECT COUNT(*) FROM recognitions WHERE user_id = $1',
      [req.user.id]
    );
    const total = parseInt(countResult.rows[0].count);

    res.json({
      success: true,
      data: {
        recognitions: result.rows,
        pagination: {
          page,
          limit,
          total,
          totalPages: Math.ceil(total / limit),
        },
      },
    });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/history/:id
const deleteHistoryItem = async (req, res, next) => {
  try {
    const result = await db.query(
      'DELETE FROM recognitions WHERE id = $1 AND user_id = $2 RETURNING id',
      [req.params.id, req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'History item not found' });
    }

    res.json({ success: true, message: 'History item deleted' });
  } catch (err) {
    next(err);
  }
};

module.exports = { recognize, getHistory, deleteHistoryItem };
