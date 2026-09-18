import axios from "axios";

const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_URL || "http://localhost:3000/api/v1",
  headers: {
    "Content-Type": "application/json",
    Accept: "application/json",
  },
  timeout: 10000,
});

export const getDevices = () => apiClient.get("/devices");
export const getDevice = (id) => apiClient.get(`/devices/${id}`);
export const triggerSync = (id) => apiClient.post(`/devices/${id}/sync`);

export default apiClient;
