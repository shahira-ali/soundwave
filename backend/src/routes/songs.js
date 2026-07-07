const router = require('express').Router();
const {
  searchSongs,
  getSong,
  getTrending,
  addFavorite,
  removeFavorite,
  getFavorites,
} = require('../controllers/songController');
const { authMiddleware } = require('../middleware/auth');

router.get('/search', searchSongs);
router.get('/trending', getTrending);
router.get('/favorites', authMiddleware, getFavorites);
router.get('/:id', getSong);
router.post('/:id/favorite', authMiddleware, addFavorite);
router.delete('/:id/favorite', authMiddleware, removeFavorite);

module.exports = router;
