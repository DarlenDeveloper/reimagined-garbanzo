/**
 * VAPI TypeScript Interfaces
 */

export interface VapiAssistantConfig {
  name: string;
  voice: {
    model: string;
    voiceId: string;
    provider: string;
    stability: number;
    similarityBoost: number;
    fallbackPlan: {
      voices: Array<{
        model: string;
        voiceId: string;
        provider: string;
        stability: number;
        similarityBoost: number;
      }>;
    };
  };
  model: {
    model: string;
    provider: string;
    maxTokens: number;
    temperature: number;
    messages: Array<{
      role: string;
      content: string;
    }>;
  };
  firstMessage: string;
  voicemailMessage: string;
  endCallMessage: string;
  endCallFunctionEnabled: boolean;
  transcriber: {
    model: string;
    language: string;
    provider: string;
    endpointing: number;
    fallbackPlan: {
      transcribers: Array<{
        model: string;
        language: string;
        provider: string;
      }>;
    };
  };
  clientMessages: string[];
  serverMessages: string[];
  serverUrl?: string;
  endCallPhrases: string[];
  hipaaEnabled: boolean;
  maxDurationSeconds: number;
  analysisPlan: {
    summaryPlan: { enabled: boolean };
    successEvaluationPlan: { enabled: boolean };
  };
  artifactPlan: {
    recordingEnabled: boolean;
    structuredOutputIds: string[];
  };
  messagePlan: {
    idleMessages: string[];
  };
  startSpeakingPlan: {
    waitSeconds: number;
    smartEndpointingEnabled: string;
  };
  compliancePlan: {
    hipaaEnabled: boolean;
    pciEnabled: boolean;
  };
}

export interface VapiPhoneNumberConfig {
  provider: string;
  number: string;
  assistantId: string;
  credentialId: string;
  name: string;
  numberE164CheckEnabled: boolean;
  server: {
    url: string;
    timeoutSeconds: number;
    backoffPlan?: {
      type: string;
      maxRetries: number;
      baseDelaySeconds: number;
      excludedStatusCodes: number[];
    };
  };
}

export interface VapiAssistantResponse {
  id: string;
  orgId: string;
  name: string;
  createdAt: string;
  updatedAt: string;
}

export interface VapiPhoneNumberResponse {
  id: string;
  orgId: string;
  number: string;
  assistantId: string;
  credentialId: string;
  provider: string;
  status: string;
  createdAt: string;
  updatedAt: string;
}

export interface VapiWebhookEvent {
  type: string;
  call?: {
    id: string;
    orgId: string;
    phoneNumber: {
      number: string;
    };
    customer?: {
      number: string;
    };
    startedAt: string;
    endedAt: string;
    transcript?: string;
    cost?: number;
    artifact?: {
      structuredOutputs?: Array<{
        id: string;
        name: string;
        result: any;
      }>;
    };
  };
}

export interface CallLogData {
  callId: string;
  customerPhone: string;
  customerName?: string;
  duration: number;
  transcript: string;
  summary: string;
  csatScore: number | null;
  cost: number;
  createdAt: FirebaseFirestore.Timestamp;
}

export interface AIServiceConfig {
  enabled: boolean;
  status: "active" | "grace_period" | "expired";
  vapiAssistantId: string | null;
  vapiPhoneNumberId: string | null;
  didId: string | null;
  phoneNumber: string | null;
  storeName: string;
  subscription: {
    plan: string;
    monthlyFee: number;
    currency: string;
    startDate: FirebaseFirestore.Timestamp;
    expiryDate: FirebaseFirestore.Timestamp;
    gracePeriodEndsAt: FirebaseFirestore.Timestamp | null;
    minutesIncluded: number;
    usedMinutes: number;
    status: "active" | "grace_period" | "expired";
    renewalCount: number;
    lastRenewalDate: FirebaseFirestore.Timestamp | null;
  };
  createdAt: FirebaseFirestore.Timestamp;
  updatedAt: FirebaseFirestore.Timestamp;
}

export interface DIDData {
  phoneNumber: string;
  assigned: boolean;
  storeId: string | null;
  vapiPhoneNumberId: string | null;
  assignedAt: FirebaseFirestore.Timestamp | null;
  unassignedAt?: FirebaseFirestore.Timestamp | null;
  createdAt: FirebaseFirestore.Timestamp;
}
