const db = require('../config/database');

// GET /api/songs/search?q=title+or+artist
const searchSongs = async (req, res, next) => {
  try {
    const query = req.query.q;
    if (!query || query.trim().length < 2) {
      return res.status(400).json({ success: false, message: 'Search query must be at least 2 characters' });
    }

    const result = await db.query(
      `SELECT id, title, artist, album, genre, cover_url, preview_url, spotify_url
       FROM songs
       WHERE to_tsvector('english', title || ' ' || artist) @@ plainto_tsquery('english', $1)
          OR title ILIKE $2
          OR artist ILIKE $2
       ORDER BY title
       LIMIT 30`,
      [query, `%${query}%`]
    );

    res.json({ success: true, data: { songs: result.rows } });
  } catch (err) {
    next(err);
  }
};

// GET /api/songs/:id
const getSong = async (req, res, next) => {
  try {
    const result = await db.query('SELECT * FROM songs WHERE id = $1', [req.params.id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Song not found' });
    }

    res.json({ success: true, data: { song: result.rows[0] } });
  } catch (err) {
    next(err);
  }
};

// GET /api/songs/trending
const getTrending = async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT s.id, s.title, s.artist, s.album, s.cover_url, s.preview_url,
              s.spotify_url, COUNT(r.id) as recognition_count
       FROM songs s
       JOIN recognitions r ON s.id = r.song_id
       WHERE r.recognized_at > NOW() - INTERVAL '7 days'
       GROUP BY s.id
       ORDER BY recognition_count DESC
       LIMIT 20`
    );

    res.json({ success: true, data: { songs: result.rows } });
  } catch (err) {
    next(err);
  }
};

// POST /api/songs/:id/favorite
const addFavorite = async (req, res, next) => {
  try {
    await db.query(
      'INSERT INTO favorites (user_id, song_id) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [req.user.id, req.params.id]
    );
    res.json({ success: true, message: 'Song added to favorites' });
  } catch (err) {
    next(err);
  }
};

// DELETE /api/songs/:id/favorite
const removeFavorite = async (req, res, next) => {
  try {
    await db.query(
      'DELETE FROM favorites WHERE user_id = $1 AND song_id = $2',
      [req.user.id, req.params.id]
    );
    res.json({ success: true, message: 'Song removed from favorites' });
  } catch (err) {
    next(err);
  }
};

// GET /api/songs/favorites
const getFavorites = async (req, res, next) => {
  try {
    const result = await db.query(
      `SELECT s.id, s.title, s.artist, s.album, s.genre, s.cover_url,
              s.preview_url, s.spotify_url, f.created_at as favorited_at
       FROM favorites f
       JOIN songs s ON f.song_id = s.id
       WHERE f.user_id = $1
       ORDER BY f.created_at DESC`,
      [req.user.id]
    );

    res.json({ success: true, data: { songs: result.rows } });
  } catch (err) {
    next(err);
  }
};

module.exports = { searchSongs, getSong, getTrending, addFavorite, removeFavorite, getFavorites };
