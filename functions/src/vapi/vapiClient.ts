import axios, {AxiosInstance} from "axios";
import {
  VapiAssistantConfig,
  VapiPhoneNumberConfig,
  VapiAssistantResponse,
  VapiPhoneNumberResponse,
} from "./types";

const VAPI_BASE_URL = "https://api.vapi.ai";

/**
 * VAPI API Client
 * Handles all communication with VAPI REST API
 */
export class VapiClient {
  private client: AxiosInstance;

  constructor(apiKey: string) {
    this.client = axios.create({
      baseURL: VAPI_BASE_URL,
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      timeout: 30000, // 30 seconds
    });
  }

  /**
   * Create a new VAPI assistant
   */
  async createAssistant(
    config: VapiAssistantConfig
  ): Promise<VapiAssistantResponse> {
    try {
      console.log("📞 Creating VAPI assistant...");
      const response = await this.client.post("/assistant", config);
      console.log(`✅ Assistant created: ${response.data.id}`);
      return response.data;
    } catch (error: any) {
      console.error("❌ Error creating assistant:", error.response?.data || error.message);
      throw new Error(
        `Failed to create assistant: ${error.response?.data?.message || error.message}`
      );
    }
  }

  /**
   * Create a new VAPI phone number
   */
  async createPhoneNumber(
    config: VapiPhoneNumberConfig
  ): Promise<VapiPhoneNumberResponse> {
    try {
      console.log(`📞 Creating VAPI phone number: ${config.number}`);
      const response = await this.client.post("/phone-number", config);
      console.log(`✅ Phone number created: ${response.data.id}`);
      return response.data;
    } catch (error: any) {
      console.error("❌ Error creating phone number:", error.response?.data || error.message);
      throw new Error(
        `Failed to create phone number: ${error.response?.data?.message || error.message}`
      );
    }
  }

  /**
   * Delete a VAPI assistant
   */
  async deleteAssistant(assistantId: string): Promise<void> {
    try {
      console.log(`🗑️ Deleting VAPI assistant: ${assistantId}`);
      await this.client.delete(`/assistant/${assistantId}`);
      console.log(`✅ Assistant deleted: ${assistantId}`);
    } catch (error: any) {
      console.error("❌ Error deleting assistant:", error.response?.data || error.message);
      throw new Error(
        `Failed to delete assistant: ${error.response?.data?.message || error.message}`
      );
    }
  }

  /**
   * Delete a VAPI phone number
   */
  async deletePhoneNumber(phoneNumberId: string): Promise<void> {
    try {
      console.log(`🗑️ Deleting VAPI phone number: ${phoneNumberId}`);
      await this.client.delete(`/phone-number/${phoneNumberId}`);
      console.log(`✅ Phone number deleted: ${phoneNumberId}`);
    } catch (error: any) {
      console.error("❌ Error deleting phone number:", error.response?.data || error.message);
      throw new Error(
        `Failed to delete phone number: ${error.response?.data?.message || error.message}`
      );
    }
  }

  /**
   * Update a VAPI assistant
   */
  async updateAssistant(
    assistantId: string,
    config: Partial<VapiAssistantConfig>
  ): Promise<VapiAssistantResponse> {
    try {
      console.log(`🔄 Updating VAPI assistant: ${assistantId}`);
      const response = await this.client.patch(`/assistant/${assistantId}`, config);
      console.log(`✅ Assistant updated: ${assistantId}`);
      return response.data;
    } catch (error: any) {
      console.error("❌ Error updating assistant:", error.response?.data || error.message);
      throw new Error(
        `Failed to update assistant: ${error.response?.data?.message || error.message}`
      );
    }
  }

  /**
   * Get assistant details
   */
  async getAssistant(assistantId: string): Promise<VapiAssistantResponse> {
    try {
      const response = await this.client.get(`/assistant/${assistantId}`);
      return response.data;
    } catch (error: any) {
      console.error("❌ Error getting assistant:", error.response?.data || error.message);
      throw new Error(
        `Failed to get assistant: ${error.response?.data?.message || error.message}`
      );
    }
  }

  /**
   * Get phone number details
   */
  async getPhoneNumber(phoneNumberId: string): Promise<VapiPhoneNumberResponse> {
    try {
      const response = await this.client.get(`/phone-number/${phoneNumberId}`);
      return response.data;
    } catch (error: any) {
      console.error("❌ Error getting phone number:", error.response?.data || error.message);
      throw new Error(
        `Failed to get phone number: ${error.response?.data?.message || error.message}`
      );
    }
  }
}
