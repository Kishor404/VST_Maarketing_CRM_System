import React, { useEffect, useState } from "react";
import axios from "axios";
import Cookies from "js-cookie";
import "../styles/attendance.css";
import { useNavigate } from 'react-router-dom';


const Attendance = () => {

  const BASEURL="http://127.0.0.1:8000";

  const today = new Date().toISOString().split("T")[0];

  const [staffList, setStaffList] = useState([]);
  const [attendance, setAttendance] = useState({});
  const [date, setDate] = useState(today);
  const [loading, setLoading] = useState(true);
  const isToday = date === today;


  const navigate = useNavigate();

    /** Redirect unauthenticated users to /head/ immediately. */
    useEffect(() => {
        const isLoggedIn = Cookies.get('Login') === 'True';
        if (!isLoggedIn) navigate('/head/');
    }, [navigate]);

  const refresh_token = async () => {
        const rToken = Cookies.get('refresh_token');

        try {
            const res = await axios.post(BASEURL+'/api/auth/token/refresh/', 
                { 'refresh': rToken }, 
                { headers: { "Content-Type": "application/json" } }
            );
            Cookies.set('refresh_token', res.data.refresh, { expires: 7 });
            return res.data.access;
        } catch (error) {
            console.error("Error refreshing token:", error);
            navigate('/head/');
            return null;
        }
    };

  // Load staff + today's attendance
  useEffect(() => {
    const loadData = async () => {
      const AT = await refresh_token();
      if (!AT) return;

      setLoading(true);

      try {
        const [staffRes, attendanceRes] = await Promise.all([
          axios.get(
            BASEURL+"/api/auth/admin/users/?role=worker",
            { headers: { Authorization: `Bearer ${AT}` } }
          ),
          axios.get(
            BASEURL+`/api/crm/attendance/by_date/?date=${date}`,
            { headers: { Authorization: `Bearer ${AT}` } }
          ),
        ]);

        setStaffList(staffRes.data);

        // default everyone absent
        const map = {};
        staffRes.data.forEach((s) => {
          map[s.id] = "absent";
        });

        // ✅ APPLY API RECORDS (FIXED)
        console.log(attendanceRes.data);
        attendanceRes.data.records.forEach((record) => {
          map[record.user_id] = record.status;
        });

        setAttendance(map);
      } catch (err) {
        console.error("Failed to load attendance", err);
      } finally {
        setLoading(false);
      }
    };

    loadData();
  }, [date]);

  const toggleAttendance = (userId, status) => {
    setAttendance((prev) => ({
      ...prev,
      [userId]: status,
    }));
  };

  const submitAttendance = async () => {
    const AT = await refresh_token();
    if (!AT) return;

    const present = [];
    const absent = [];

    Object.entries(attendance).forEach(([id, status]) => {
      status === "present"
        ? present.push(Number(id))
        : absent.push(Number(id));
    });

    try {
      await axios.post(
        BASEURL+"/api/crm/attendance/bulk/",
        { date: today, present, absent },
        {
          headers: {
            Authorization: `Bearer ${AT}`,
            "Content-Type": "application/json",
          },
        }
      );

      alert("Attendance saved successfully");
    } catch (err) {
      console.error(err);
      alert("Failed to save attendance");
    }
  };

  return (
    <div className="attendance-container">
      


      <div className="attendance-top">
        <div>
          <h3>STAFF ATTENDANCE</h3>
      {!isToday && (
        <p className="attendance-note">
          Attendance can be taken only for today
        </p>
      )}
        </div>
        <div className="attendance-top-right">
          <input
            type="date"
            value={date}
            max={today}   // 🔒 no future dates
            onChange={(e) => setDate(e.target.value)}
          />


        <button
          onClick={submitAttendance}
          className="save-btn"
          disabled={!isToday}
        >
          SAVE
        </button>
        </div>
          

      </div>
      <div className="attendance-table-cont">

        <table className="attendance-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Present</th>
              <th>Absent</th>
            </tr>
          </thead>
          <tbody>
            {staffList.map((staff) => (
              <tr key={staff.id}>
                <td style={{ fontWeight: '600', color: '#64748b' }}>#{staff.id}</td>
                <td style={{ fontWeight: '500' }}>{staff.name}</td>
                <td className="text-center">
                  <input
                    type="radio"
                    name={`status-${staff.id}`} // Added name for accessibility
                    disabled={!isToday}
                    checked={attendance[staff.id] === "present"}
                    onChange={() => toggleAttendance(staff.id, "present")}
                  />
                </td>
                <td className="text-center">
                  <input
                    type="radio"
                    name={`status-${staff.id}`} // Added name for accessibility
                    disabled={!isToday}
                    checked={attendance[staff.id] === "absent"}
                    onChange={() => toggleAttendance(staff.id, "absent")}
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>

      </div>
      
    </div>
  );
};

export default Attendance;
