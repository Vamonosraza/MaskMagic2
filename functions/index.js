const functions = require("firebase-functions");
const axios = require("axios");
const FormData = require("form-data");

/**
 * Helper function to convert base64 data URI to buffer.
 * @param {string} dataURI - The data URI containing base64 image data.
 * @return {Buffer} The extracted buffer from base64 string.
 */
function dataURItoBuffer(dataURI) {
  // Extract base64 content from data URI
  const matches = dataURI.match(/^data:([A-Za-z-+/]+);base64,(.+)$/);
  if (!matches || matches.length !== 3) {
    throw new Error("Invalid data URI format");
  }
  // Log important details for debugging
  console.log({
    structuredData: true,
    message: "Extracting buffer",
    contentType: matches[1],
    dataLength: matches[2].length,
  });
  return Buffer.from(matches[2], "base64");
}

/**
 * Cloud function to generate an image using OpenAI's image editing API.
 */
exports.generateImage = functions.https.onRequest(async (req, res) => {
  // Enable CORS
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  try {
    console.log({
      structuredData: true,
      message: "Received request to generate image",
    });

    // Extract parameters from request body
    const {
      image,
      mask,
      prompt,
      model = "dall-e-2",
      size = "1024x1024",
      // eslint-disable-next-line camelcase
      response_format = "url",
    } = req.body;

    // Log the incoming data structure
    console.log({
      structuredData: true,
      message: "Request parameters",
      hasImage: !!image,
      hasMask: !!mask,
      promptLength: prompt ? prompt.length : 0,
      imageStartsWith: image ? image.substring(0, 30) + "..." : null,
      maskStartsWith: mask ? mask.substring(0, 30) + "..." : null,
    });

    if (!image || !mask || !prompt) {
      return res.status(400).json({error: "Missing required parameters"});
    }

    // Get API key from environment variable
    const apiKey = process.env.OPENAI_API_KEY;
    if (!apiKey) {
      console.error({
        structuredData: true,
        message: "API key not configured in environment variables",
      });
      return res.status(500).json({error: "Server configuration error"});
    }

    // Convert base64 data URIs to buffers
    let imageBuffer;
    let maskBuffer;
    try {
      imageBuffer = dataURItoBuffer(image);
      maskBuffer = dataURItoBuffer(mask);

      console.log({
        structuredData: true,
        message: "Converted images to buffers",
        imageBufferSize: imageBuffer.length,
        maskBufferSize: maskBuffer.length,
      });
    } catch (error) {
      console.error({
        structuredData: true,
        message: "Error processing images",
        error: error.message,
      });
      return res.status(400).json({
        error: "Invalid image format. Must be data URI with base64 encoding.",
      });
    }

    // Create form data for OpenAI API
    const form = new FormData();

    // Add buffers directly
    form.append("image", imageBuffer, {
      filename: "image.png",
      contentType: "image/png",
    });

    form.append("mask", maskBuffer, {
      filename: "mask.png",
      contentType: "image/png",
    });

    // Add other parameters
    form.append("prompt", prompt);
    form.append("model", model);
    form.append("size", size);
    // eslint-disable-next-line camelcase
    form.append("response_format", response_format);

    console.log({
      structuredData: true,
      message: "Calling OpenAI API",
      prompt: prompt,
      model: model,
      size: size,
    });

    // Make the API request to OpenAI
    try {
      const openaiResponse = await axios.post(
          "https://api.openai.com/v1/images/edits",
          form,
          {
            headers: {
              ...form.getHeaders(),
              "Authorization": `Bearer ${apiKey}`,
            },
            maxBodyLength: Infinity,
            maxContentLength: Infinity,
          },
      );

      console.log({
        structuredData: true,
        message: "OpenAI API success",
        statusCode: openaiResponse.status,
      });

      // Forward the OpenAI response
      return res.status(200).json(openaiResponse.data);
    } catch (apiError) {
      // Fixed optional chaining error
      const statusCode = apiError.response ? apiError.response.status : null;
      const errorData = apiError.response && apiError.response.data ?
                         apiError.response.data : "No detailed error info";

      console.error({
        structuredData: true,
        message: "Error calling OpenAI API",
        error: apiError.message,
        status: statusCode,
        details: errorData,
      });

      if (apiError.response) {
        return res.status(apiError.response.status).json({
          error: "OpenAI API error",
          details: apiError.response.data,
        });
      }

      return res.status(500).json({error: "Failed to generate image"});
    }
  } catch (error) {
    console.error({
      structuredData: true,
      message: "Unexpected error",
      error: error.message,
      stack: error.stack,
    });
    return res.status(500).json({error: "Internal server error"});
  }
});
