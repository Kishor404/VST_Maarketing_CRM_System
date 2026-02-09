import React from "react";
import { BrowserRouter as Router, Routes, Route, useLocation, Outlet } from "react-router-dom";
import Login from "./pages/Login";
import Customer from "./pages/customer";
import Staff from "./pages/staff";
import CreateCard from "./pages/createcard";
import Service from "./pages/service";
import Sidebar from "./components/Sidebar";
import ShowCard from "./pages/showcard";
import NotFound from "./pages/NotFound";
import "./App.css";
import Attendance from './pages/attendance';
import Warranty from './pages/warranty';
import Reminder from "./pages/reminder";
import FollowUp from "./pages/followup";
import AMC from "./pages/amc";
import IndustrialAMC from "./pages/industrial_amc";
import JobCard from "./pages/jobcard";

const HeadLayout = () => {
  const location = useLocation();
  const showSidebar = !/^\/head\/?$/.test(location.pathname);

  return (
    <div className="app-container">
      {showSidebar && <Sidebar />}
      <div className="content">
        <Outlet />
      </div>
    </div>
  );
};

const App = () => {
  return (
    <Router>
      <Routes>
        {/* All /head... pages */}
        <Route path="/head" element={<HeadLayout />}>
          <Route index element={<Login />} />
          <Route path="customer" element={<Customer />} />
          <Route path="staff" element={<Staff />} />
          <Route path="createcard" element={<CreateCard />} />
          <Route path="showcard" element={<ShowCard />} />
          <Route path="service" element={<Service />} />
          <Route path="jobcard" element={<JobCard />} />
          <Route path="warranty" element={<Warranty />} />
          <Route path="amc" element={<AMC />} />
          <Route path="industrialamc" element={<IndustrialAMC />} />
          <Route path="attendance" element={<Attendance />} />
          <Route path="reminder" element={<Reminder />} />
          <Route path="followup" element={<FollowUp />} />
        </Route>

        {/* All OTHER ROUTES ➔ NotFound */}
        <Route path="*" element={<NotFound />} />
      </Routes>
    </Router>
  );
};

export default App;
