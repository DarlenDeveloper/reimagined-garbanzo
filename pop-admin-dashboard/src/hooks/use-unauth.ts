import { useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "@contexts/AuthContext";

/**
 * useUnauth hook to protect auth routes after login
 * Redirects to home if user is already authenticated
 */
const useUnauth = () => {
  const navigate = useNavigate();
  const { user, loading } = useAuth();

  useEffect(() => {
    if (!loading && user) {
      navigate("/");
    }
  }, [user, loading, navigate]);
};

export default useUnauth;
