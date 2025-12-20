// src/api/axiosInstance.js
import axios from 'axios';
import Cookies from 'js-cookie';

const BASEURL = "http://157.173.220.208";

const api = axios.create({
  baseURL: BASEURL+'/api/',
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add request interceptor to attach access token
api.interceptors.request.use(
  (config) => {
    const token = Cookies.get('access_token');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Add response interceptor to handle 401 and refresh token
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      const rToken = Cookies.get('refresh_token');
      if (!rToken) {
        //window.location.href = '/head/';
        return Promise.reject(error);
      }

      try {
        const res = await axios.post(
          BASEURL+'/api/auth/token/refresh/',
          { refresh: rToken },
          { headers: { 'Content-Type': 'application/json' } }
        );
        const newAccessToken = res.data.access;
        const newRefreshToken = res.data.refresh;

        Cookies.set('access_token', newAccessToken, { expires: 7 });
        Cookies.set('refresh_token', newRefreshToken, { expires: 7 });

        originalRequest.headers['Authorization'] = `Bearer ${newAccessToken}`;
        return api(originalRequest);
      } catch (refreshError) {
        console.error('Token refresh failed:', refreshError);
        //window.location.href = '/head/';
        return Promise.reject(error);
      }
    }
    return Promise.reject(error);
  }
);

export default api;
