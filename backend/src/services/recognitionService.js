const axios = require('axios');
const FormData = require('form-data');
const crypto = require('crypto');

/**
 * Recognize a song using ACRCloud API.
 * Falls back to Audd.io if ACRCloud credentials are not set.
 */
async function recognizeSong(audioBuffer, mimeType = 'audio/wav') {
  const useACRCloud =
    process.env.ACRCLOUD_HOST &&
    process.env.ACRCLOUD_ACCESS_KEY &&
    process.env.ACRCLOUD_ACCESS_SECRET;

  if (useACRCloud) {
    return recognizeWithACRCloud(audioBuffer);
  } else if (process.env.AUDD_API_TOKEN) {
    return recognizeWithAudd(audioBuffer, mimeType);
  } else {
    throw new Error(
      'No music recognition API configured. Please set ACRCLOUD or AUDD credentials in .env'
    );
  }
}

/**
 * ACRCloud recognition
 * https://docs.acrcloud.com/reference/identification-api
 */
async function recognizeWithACRCloud(audioBuffer) {
  const host = process.env.ACRCLOUD_HOST;
  const accessKey = process.env.ACRCLOUD_ACCESS_KEY;
  const accessSecret = process.env.ACRCLOUD_ACCESS_SECRET;
  const dataType = 'audio';
  const signatureVersion = '1';
  const timestamp = Math.floor(Date.now() / 1000).toString();

  const stringToSign = [
    'POST',
    '/v1/identify',
    accessKey,
    dataType,
    signatureVersion,
    timestamp,
  ].join('\n');

  const signature = crypto
    .createHmac('sha1', accessSecret)
    .update(Buffer.from(stringToSign, 'utf-8'))
    .digest('base64');

  const formData = new FormData();
  formData.append('sample', audioBuffer, { filename: 'sample.wav', contentType: 'audio/wav' });
  formData.append('access_key', accessKey);
  formData.append('data_type', dataType);
  formData.append('signature_version', signatureVersion);
  formData.append('signature', signature);
  formData.append('timestamp', timestamp);
  formData.append('sample_bytes', audioBuffer.length.toString());

  const response = await axios.post(`https://${host}/v1/identify`, formData, {
    headers: formData.getHeaders(),
    timeout: 15000,
  });

  const data = response.data;

  if (data.status.code !== 0) {
    if (data.status.code === 1001) {
      return { found: false };
    }
    throw new Error(`ACRCloud error: ${data.status.msg}`);
  }

  const music = data.metadata.music[0];
  return {
    found: true,
    song: {
      title: music.title,
      artist: music.artists ? music.artists.map((a) => a.name).join(', ') : 'Unknown Artist',
      album: music.album ? music.album.name : null,
      release_date: music.release_date || null,
      genre: music.genres ? music.genres[0].name : null,
      cover_url: null,
      preview_url: null,
      isrc: music.external_ids ? music.external_ids.isrc : null,
      acrid: music.acrid || null,
      spotify_url: music.external_metadata?.spotify?.track?.id
        ? `https://open.spotify.com/track/${music.external_metadata.spotify.track.id}`
        : null,
      apple_music_url: music.external_metadata?.deezer?.track?.id
        ? `https://www.deezer.com/track/${music.external_metadata.deezer.track.id}`
        : null,
    },
    score: music.score,
  };
}

/**
 * Audd.io recognition
 * https://docs.audd.io
 */
async function recognizeWithAudd(audioBuffer, mimeType) {
  const formData = new FormData();
  formData.append('file', audioBuffer, { filename: 'sample.wav', contentType: mimeType });
  formData.append('api_token', process.env.AUDD_API_TOKEN);
  formData.append('return', 'spotify,apple_music,deezer');

  const response = await axios.post('https://api.audd.io/', formData, {
    headers: formData.getHeaders(),
    timeout: 15000,
  });

  const data = response.data;

  if (data.status === 'error') {
    throw new Error(`Audd.io error: ${data.error.error_message}`);
  }

  if (!data.result) {
    return { found: false };
  }

  const result = data.result;
  return {
    found: true,
    song: {
      title: result.title,
      artist: result.artist,
      album: result.album,
      release_date: result.release_date,
      genre: null,
      cover_url: result.spotify?.album?.images?.[0]?.url || null,
      preview_url: result.spotify?.preview_url || null,
      isrc: result.spotify?.external_ids?.isrc || null,
      acrid: null,
      spotify_url: result.spotify?.external_urls?.spotify || null,
      apple_music_url: result.apple_music?.url || null,
      youtube_url: null,
    },
    score: 100,
  };
}

module.exports = { recognizeSong };
