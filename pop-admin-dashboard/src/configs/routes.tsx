import AuthLayout from "@layouts/auth/auth-layout";
import { DashboardLayout } from "@layouts/dashboard/dashboard-layout";
import RootLayout from "@layouts/root/root-layout";
import { Error404, Login } from "@pages/index";
import {
  UsersPage,
  OrdersPage,
  PaymentsPage,
  StoreVerificationPage,
  CourierVerificationPage,
  PayoutsPage,
  DIDPoolPage,
  AnalyticsDashboard,
  StoresPage,
  CouriersPage,
  AdminUsersPage,
  NotificationsPage,
  FinancialPage,
} from "@pages/pop-admin/index";
import { StoreDetailPage } from "@pages/pop-admin/stores/store-detail-page";
import { CourierDetailPage } from "@pages/pop-admin/couriers/courier-detail-page";
import { UserDetailPage } from "@pages/pop-admin/users/user-detail-page";
import { ProtectedRoute } from "@components/auth/ProtectedRoute";
import { createBrowserRouter, Navigate } from "react-router-dom";

export const router = createBrowserRouter([
  {
    path: "/",
    element: <RootLayout />,
    children: [
      {
        path: "",
        element: (
          <ProtectedRoute>
            <DashboardLayout />
          </ProtectedRoute>
        ),
        children: [
          {
            index: true,
            element: <Navigate to="analytics" replace />,
          },
          {
            path: "analytics",
            element: <AnalyticsDashboard />,
          },
          {
            path: "users",
            element: <UsersPage />,
          },
          {
            path: "users/:userId",
            element: <UserDetailPage />,
          },
          {
            path: "stores",
            element: <StoresPage />,
          },
          {
            path: "stores/:storeId",
            element: <StoreDetailPage />,
          },
          {
            path: "orders",
            element: <OrdersPage />,
          },
          {
            path: "payments",
            element: (
              <ProtectedRoute requiredPermission="payments">
                <PaymentsPage />
              </ProtectedRoute>
            ),
          },
          {
            path: "couriers",
            element: <CouriersPage />,
          },
          {
            path: "couriers/:courierId",
            element: <CourierDetailPage />,
          },
          {
            path: "store-verification",
            element: <StoreVerificationPage />,
          },
          {
            path: "courier-verification",
            element: <CourierVerificationPage />,
          },
          {
            path: "payouts",
            element: (
              <ProtectedRoute requiredPermission="payouts">
                <PayoutsPage />
              </ProtectedRoute>
            ),
          },
          {
            path: "notifications",
            element: <NotificationsPage />,
          },
          {
            path: "financial",
            element: (
              <ProtectedRoute requiredPermission="financial">
                <FinancialPage />
              </ProtectedRoute>
            ),
          },
          {
            path: "did-pool",
            element: <DIDPoolPage />,
          },
          {
            path: "admin-users",
            element: (
              <ProtectedRoute requiredPermission="admin_users">
                <AdminUsersPage />
              </ProtectedRoute>
            ),
          },
        ],
      },
      {
        path: "auth",
        element: <AuthLayout />,
        children: [
          {
            index: true,
            path: "login",
            element: <Login />,
          },
        ],
      },
    ],
  },
  {
    path: "/*",
    element: <Error404 />,
  },
]);
