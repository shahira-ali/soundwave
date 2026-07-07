const router = require('express').Router();
const multer = require('multer');
const { recognize, getHistory, deleteHistoryItem } = require('../controllers/recognitionController');
const { authMiddleware, optionalAuth } = require('../middleware/auth');

// Store audio in memory (max 10MB)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (req, file, cb) => {
    const allowed = ['audio/wav', 'audio/mpeg', 'audio/mp4', 'audio/ogg', 'audio/webm', 'audio/x-m4a'];
    if (allowed.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Invalid audio format. Use WAV, MP3, MP4, OGG, or WebM.'));
    }
  },
});

// POST /api/recognize - works with or without auth (history saved only if logged in)
router.post('/', optionalAuth, upload.single('audio'), recognize);

// GET /api/history - requires auth
router.get('/history', authMiddleware, getHistory);

// DELETE /api/history/:id
router.delete('/history/:id', authMiddleware, deleteHistoryItem);

module.exports = router;
