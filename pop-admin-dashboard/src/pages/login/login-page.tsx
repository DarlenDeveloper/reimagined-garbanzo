import { Form } from "@components/ui/form";
import { toast } from "sonner";
import Text from "@components/commons/text";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { loginSchema } from "./schemas/login-schema";
import TextInput from "@components/inputs/text-input";
import PasswordInput from "@components/inputs/password-input";
import { Button } from "@components/ui/button";
import { useAuth } from "@contexts/AuthContext";
import { useNavigate } from "react-router-dom";
import { useTranslation } from "react-i18next";
import { useState } from "react";

type FormType = {
  username: string;
  password: string;
};

export function Login() {
  const { signIn } = useAuth();
  const navigate = useNavigate();
  const { t } = useTranslation();
  const [loading, setLoading] = useState(false);
  
  const form = useForm<FormType>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      username: "",
      password: "",
    },
  });

  async function onSubmit(values: FormType) {
    setLoading(true);
    try {
      await signIn(values.username, values.password);
      toast.success("Login successful!");
      // Wait a bit for auth state to update, then navigate
      setTimeout(() => {
        navigate("/analytics");
      }, 100);
    } catch (error: any) {
      toast.error(error.message || "Failed to login");
    } finally {
      setLoading(false);
    }
  }

  return (
    <Form {...form}>
      <form
        onSubmit={form.handleSubmit(onSubmit)}
        className="border rounded-lg p-4 space-y-4 w-full sm:w-[400px]"
      >
        <div>
          <Text size="xxl">{t("login.loginHere")}</Text>
          <Text className="text-muted-foreground">
            Enter your admin credentials
          </Text>
        </div>

        <TextInput
          label={t("login.username")}
          placeholder="Enter your email"
          name="username"
          withAsterisk
          form={form}
        />

        <PasswordInput
          label={t("login.password")}
          placeholder={t("login.enterPassword")}
          name="password"
          withAsterisk
          form={form}
        />

        <Button type="submit" fullWidth disabled={loading}>
          {loading ? "Signing in..." : t("login.login")}
        </Button>
      </form>
    </Form>
  );
}
