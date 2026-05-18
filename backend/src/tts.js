const googleTTS = require('google-tts-api');
const axios = require('axios');

async function generateSpeechUrl(text) {
  const url = googleTTS.getAudioUrl(text, {
    lang: 'ru', // или 'kk'
    slow: false,
    host: 'https://translate.google.com',
  });

  return url;
}

module.exports = { generateSpeechUrl };