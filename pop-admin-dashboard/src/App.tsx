import { ThemeProvider } from "@components/theme/theme-provider";
import { Toaster } from "@components/ui/sonner";
import { router } from "@configs/routes";
import { RouterProvider } from "react-router-dom";
import { QueryClientProvider, QueryClient } from "@tanstack/react-query";
import { AuthProvider } from "@contexts/AuthContext";

const queryClient = new QueryClient();

function App() {
  console.log("App component rendering...");
  
  try {
    return (
      <QueryClientProvider client={queryClient}>
        <AuthProvider>
          <ThemeProvider defaultTheme="light" storageKey="vite-ui-theme">
            <RouterProvider router={router} />
            <Toaster position="top-center" />
          </ThemeProvider>
        </AuthProvider>
      </QueryClientProvider>
    );
  } catch (error) {
    console.error("Error rendering App:", error);
    return <div>Error loading app. Check console.</div>;
  }
}

export default App;
