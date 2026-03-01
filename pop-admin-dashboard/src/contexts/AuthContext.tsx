import { createContext, useContext, useEffect, useState } from "react";
import type { ReactNode } from "react";
import { 
  signInWithEmailAndPassword, 
  signOut as firebaseSignOut,
  onAuthStateChanged 
} from "firebase/auth";
import type { User } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";
import { auth, db } from "@lib/firebase";

type AdminRole = "super_admin" | "accountant" | "customer_service" | "analyst";

interface AdminUser {
  uid: string;
  email: string;
  name: string;
  role: AdminRole;
  permissions: string[];
}

interface AuthContextType {
  user: User | null;
  adminUser: AdminUser | null;
  loading: boolean;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
  hasPermission: (permission: string) => boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [adminUser, setAdminUser] = useState<AdminUser | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    console.log("AuthProvider: Setting up auth listener");
    
    // Set a timeout to prevent infinite loading
    const loadingTimeout = setTimeout(() => {
      console.log("AuthProvider: Loading timeout reached");
      setLoading(false);
    }, 5000);

    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      try {
        console.log("AuthProvider: Auth state changed", firebaseUser?.uid);
        setUser(firebaseUser);
        
        if (firebaseUser) {
          // Fetch admin user data from Firestore
          console.log("Checking admin status for user:", firebaseUser.uid);
          const adminDoc = await getDoc(doc(db, "admins", firebaseUser.uid));
          
          if (adminDoc.exists()) {
            const adminData = adminDoc.data() as AdminUser;
            console.log("Admin user found:", adminData);
            setAdminUser(adminData);
            setError(null);
          } else {
            console.log("User is not an admin, signing out");
            setAdminUser(null);
            setError("Not authorized");
            await firebaseSignOut(auth);
          }
        } else {
          console.log("No user signed in");
          setAdminUser(null);
          setError(null);
        }
      } catch (err: any) {
        console.error("Error in auth state change:", err);
        setError(err.message);
        setAdminUser(null);
      } finally {
        clearTimeout(loadingTimeout);
        setLoading(false);
        console.log("AuthProvider: Loading complete");
      }
    });

    return () => {
      clearTimeout(loadingTimeout);
      unsubscribe();
    };
  }, []);

  const signIn = async (email: string, password: string) => {
    try {
      console.log("Attempting to sign in with:", email);
      const userCredential = await signInWithEmailAndPassword(auth, email, password);
      console.log("Sign in successful, checking admin status...");
      
      // Check if user is an admin
      const adminDoc = await getDoc(doc(db, "admins", userCredential.user.uid));
      if (!adminDoc.exists()) {
        console.log("User is not an admin");
        await firebaseSignOut(auth);
        throw new Error("UNAUTHORIZED");
      }
      
      console.log("Admin verified:", adminDoc.data());
    } catch (error: any) {
      console.error("Sign in error:", error);
      
      // Sanitize error messages - don't reveal Firebase details
      if (error.message === "UNAUTHORIZED") {
        throw new Error("Invalid email or password");
      }
      
      // Map Firebase errors to generic messages
      const errorCode = error.code;
      if (errorCode === "auth/user-not-found" || 
          errorCode === "auth/wrong-password" || 
          errorCode === "auth/invalid-credential" ||
          errorCode === "auth/invalid-email") {
        throw new Error("Invalid email or password");
      } else if (errorCode === "auth/too-many-requests") {
        throw new Error("Too many failed attempts. Please try again later");
      } else if (errorCode === "auth/network-request-failed") {
        throw new Error("Network error. Please check your connection");
      } else {
        throw new Error("Login failed. Please try again");
      }
    }
  };

  const signOut = async () => {
    await firebaseSignOut(auth);
    setAdminUser(null);
  };

  const hasPermission = (permission: string): boolean => {
    if (!adminUser) return false;
    if (adminUser.role === "super_admin") return true;
    return adminUser.permissions.includes(permission);
  };

  const value = {
    user,
    adminUser,
    loading,
    signIn,
    signOut,
    hasPermission,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
}
