const apiCall =
  (method) =>
  async (url, body = {}) => {
    try {
      const fetchInit = method === "GET" ? { method } : { method, body };
      const response = await fetch(url, fetchInit);
      const isJson = response.headers.get("content-type")?.includes("application/json");
      if (!isJson) {
        return response.ok;
      }
      const data = await response.json();
      if (!response.ok) {
        throw new Error(data.message);
      }
      return data;
    } catch (error) {
      console.error(error);
      return null;
    }
  };

const utils = {
  apiGET: apiCall("GET"),
  apiPOST: apiCall("POST"),
  apiPATCH: apiCall("PATCH"),
  apiPUT: apiCall("PUT"),
  apiDELETE: apiCall("DELETE"),
  getFormData: (object) => {
    const formData = new FormData();
    Object.keys(object).forEach((key) => formData.append(key, object[key]));
    return formData;
  },
};
