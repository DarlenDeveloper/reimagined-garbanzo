import { initializeAppCheck, ReCaptchaV3Provider } from "firebase/app-check";
import type { FirebaseApp } from "firebase/app";

// Initialize Firebase App Check
export const initAppCheck = (app: FirebaseApp) => {
  if (typeof window !== 'undefined') {
    try {
      const appCheck = initializeAppCheck(app, {
        provider: new ReCaptchaV3Provider(import.meta.env.VITE_RECAPTCHA_SITE_KEY || '6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI'),
        isTokenAutoRefreshEnabled: true
      });
      console.log('App Check initialized');
      return appCheck;
    } catch (error) {
      console.error('App Check initialization failed:', error);
    }
  }
};
