import axios from 'axios';

const apiClient = axios.create({
  baseURL: '/',
  withCredentials: true,
  headers: {
    'Content-Type': 'application/json',
  },
});

apiClient.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response?.data) {
      // Handle various backend error formats (.NET usually has 'message' or 'title', or it's just a string)
      const data = error.response.data;
      const message = typeof data === 'string' ? data : (data.msg || data.message || data.title || error.message);
      return Promise.reject(new Error(message));
    }
    return Promise.reject(error);
  }
);

export default apiClient;
