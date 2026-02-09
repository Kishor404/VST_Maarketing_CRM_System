// src/pages/IndustrialAMC.jsx

import React, { useState, useEffect } from "react";
import api from "../api/axiosInstance";
import "../styles/amc.css";
import "../styles/createcard.css";
import CreateCardimg from "../assets/createcard.jpg";

import * as XLSX from "xlsx";
import { saveAs } from "file-saver";

/* ---------------- PAGE ---------------- */

const IndustrialAMC = () => {

  /* ---------- STATES ---------- */

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const [cards, setCards] = useState([]);
  const [staffList, setStaffList] = useState([]);

  const [selectedMonth, setSelectedMonth] = useState("");

  const [selectedStaff, setSelectedStaff] = useState({});
  const [attendanceMap, setAttendanceMap] = useState({});
  const [scheduledDates, setScheduledDates] = useState({});

  const [bulkBooking, setBulkBooking] = useState(false);

  /* ---------- CREATE AMC PANEL ---------- */

  const [showCreateAMC, setShowCreateAMC] = useState(false);

  const [customer, setCustomer] = useState(null);
  const [customerCards, setCustomerCards] = useState([]);

  const [selectedCard, setSelectedCard] = useState("");
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [intervalMonths, setIntervalMonths] = useState(4);

  /* ---------------- UTIL ---------------- */

  const addDays = (dateStr, days) => {
    const d = new Date(dateStr);
    d.setDate(d.getDate() + days);
    return d.toISOString().split("T")[0];
  };

  const formatDate = (dateInput) => {
    const date = new Date(dateInput);
    if (isNaN(date)) return null;

    return `${String(date.getDate()).padStart(2, "0")}/${String(
      date.getMonth() + 1
    ).padStart(2, "0")}/${date.getFullYear()}`;
  };

  /* ---------------- MONTH OPTIONS ---------------- */

  const generateMonthOptions = () => {
    const options = [];
    const now = new Date();

    for (let offset = -3; offset <= 9; offset++) {
      const d = new Date(now.getFullYear(), now.getMonth() + offset, 1);

      options.push({
        value: `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`,
        label: d.toLocaleString("default", { month: "long", year: "numeric" }),
      });
    }

    return options;
  };

  const monthOptions = generateMonthOptions();

  /* ---------------- FETCH INDUSTRIAL AMC ---------------- */

  const fetchIndustrialAMC = async (month) => {

    setLoading(true);
    setError("");

    try {

      const res = await api.get("/crm/reports/industrial-amc/", {
        params: { month },
      });

      setCards(res.data);

      const dateDefaults = {};
      const staffDefaults = {};

      res.data.forEach((card) => {

        if (card.status === "done" && card.scheduled_date) {
          dateDefaults[card.card_id] = card.scheduled_date;
        } else if (card.milestone) {
          dateDefaults[card.card_id] = card.milestone;
        }

        if (card.status === "done" && card.staff) {
          staffDefaults[card.card_id] = card.staff.staff_id;
        }
      });

      setScheduledDates(dateDefaults);
      setSelectedStaff(staffDefaults);

    } catch {
      setError("Failed to load Industrial AMC data");
    } finally {
      setLoading(false);
    }
  };

  /* ---------------- STAFF ---------------- */

  const fetchStaffList = async () => {
    try {
      const res = await api.get("/auth/admin/users/", {
        params: { role: "worker" },
      });
      setStaffList(res.data);
    } catch (err) {
      console.error(err);
    }
  };

  /* ---------------- ATTENDANCE ---------------- */

  const fetchTodayAttendance = async () => {

    const today = new Date().toISOString().split("T")[0];

    try {

      const res = await api.get("/crm/attendance/by_date/", {
        params: { date: today },
      });

      const map = {};
      res.data.records.forEach((r) => {
        map[r.user_id] = r.status;
      });

      setAttendanceMap(map);

    } catch (err) {
      console.error(err);
    }
  };

  /* ---------------- INIT ---------------- */

  useEffect(() => {

    const now = new Date();
    const month = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(
      2,
      "0"
    )}`;

    setSelectedMonth(month);

    fetchIndustrialAMC(month);
    fetchStaffList();
    fetchTodayAttendance();

  }, []);

  /* ---------------- HANDLERS ---------------- */

  const handleMonthChange = (e) => {
    const month = e.target.value;
    setSelectedMonth(month);
    fetchIndustrialAMC(month);
  };

  const handleStaffChange = (cardId, staffId) => {
    setSelectedStaff((prev) => ({
      ...prev,
      [cardId]: staffId || undefined,
    }));
  };

  const handleScheduledDateChange = (cardId, value) => {
    setScheduledDates((prev) => ({
      ...prev,
      [cardId]: value,
    }));
  };

  /* ---------------- BULK BOOK ---------------- */

  const handleBulkBook = async () => {

    if (!window.confirm("Bulk book Industrial AMC services?")) return;

    setBulkBooking(true);

    try {

      const bookingPromises = cards
        .filter((c) => selectedStaff[c.card_id])
        .map(async (card) => {

          const payload = {
            card: card.card_id,
            description: "Free Industrial AMC Service",
            service_type: "free",
            preferred_date: scheduledDates[card.card_id],
            scheduled_at: scheduledDates[card.card_id],
            visit_type: "MS",
            requested_by: card.customer_id,
            assigned_to: selectedStaff[card.card_id],
          };

          try {
            await api.post("/crm/services/admin_create/", payload);
            return true;
          } catch {
            return false;
          }
        });

      await Promise.all(bookingPromises);

      fetchIndustrialAMC(selectedMonth);

    } catch {
      setError("Bulk booking failed");
    } finally {
      setBulkBooking(false);
    }
  };

  /* ---------------- EXPORT EXCEL ---------------- */

  const exportExcel = () => {

    if (!cards.length) return alert("No data");

    const data = cards.map((card, i) => ({
      "S.No": i + 1,
      Milestone: formatDate(card.milestone),
      Customer: card.customer_name,
      Phone: card.customer_phone,
      City: card.city,
      Status: card.status,
      Interval: card.interval_months + " months",
    }));

    const ws = XLSX.utils.json_to_sheet(data);
    const wb = XLSX.utils.book_new();

    XLSX.utils.book_append_sheet(wb, ws, "Industrial AMC");

    const buffer = XLSX.write(wb, { type: "array", bookType: "xlsx" });

    saveAs(
      new Blob([buffer]),
      `Industrial_AMC_${selectedMonth}.xlsx`
    );
  };

  /* ---------------- CREATE INDUSTRIAL AMC ---------------- */

  const getUserByPhone = async (phone) => {

    if (phone.length !== 10) {
      setCustomer(null);
      return;
    }

    try {

      const res = await api.get(
        `/auth/admin/users/?phone=${phone}&role=customer`
      );

      if (res.data.length > 0) {

        const user = res.data[0];

        if (!user.is_industrial) {
          alert("Customer is NOT Industrial");
          return;
        }

        setCustomer(user);

        fetchCustomerCards(user.id);

      } else {
        setCustomer(null);
      }

    } catch (error) {
      console.error(error);
    }
  };

  const fetchCustomerCards = async (customerId) => {
    try {
      const res = await api.get(`/crm/cards/?customer=${customerId}`);
      setCustomerCards(res.data);
    } catch (err) {
      console.error(err);
    }
  };

  const createAMC = async () => {

    if (!selectedCard || !startDate || !endDate || !intervalMonths) {
      alert("Fill all fields");
      return;
    }

    if (!window.confirm("Create Industrial AMC?")) return;

    try {

      await api.post(`/crm/industrial-amc/`, {
        card: selectedCard,
        start_date: startDate,
        end_date: endDate,
        interval_months: Number(intervalMonths),
      });

      alert("Industrial AMC Created");

      setShowCreateAMC(false);
      fetchIndustrialAMC(selectedMonth);

    } catch (err) {
      console.error(err);
      alert("Failed to create Industrial AMC");
    }
  };

  /* ---------------- UI ---------------- */

  return (
    <div className="amc-container">

      {error && <div className="alert alert-error">{error}</div>}

      {/* ================= CONTROLS ================= */}

      <div className="controls-row">

        <h2 className="amc-title">Industrial AMC Services</h2>

        <div className="form-form">

          <select
            className="form-select"
            value={selectedMonth}
            onChange={handleMonthChange}
          >
            {monthOptions.map((opt) => (
              <option key={opt.value} value={opt.value}>
                {opt.label}
              </option>
            ))}
          </select>

          <button
            className="btn btn-warning"
            onClick={() => setShowCreateAMC(!showCreateAMC)}
          >
            {showCreateAMC ? "Close Create AMC" : "Create Industrial AMC"}
          </button>

          <button
            className="btn btn-primary"
            onClick={handleBulkBook}
            disabled={bulkBooking}
          >
            {bulkBooking ? "Booking..." : "Bulk Book"}
          </button>

          <button className="btn btn-secondary" onClick={exportExcel}>
            Export Excel
          </button>

        </div>
      </div>

      {/* ================= CREATE AMC PANEL ================= */}

      {showCreateAMC && (
        <div className="createcard-cont">

          <div className="createcard-l">
            <div className="createcard-card">

              <p className="createcard-title">Create Industrial AMC</p>

              <div className="createcard-inputs">

                <div className="createcard-input-cont">
                  <p>
                    Customer :
                    {customer ? ` ${customer.name}` : " Not Found"}
                  </p>

                  <input
                    className="createcard-card-input"
                    placeholder="Customer Phone"
                    onChange={(e) => getUserByPhone(e.target.value)}
                  />
                </div>

                {customer && (
                  <div className="createcard-input-cont">
                    <p>Select Card *</p>

                    <select
                      className="createcard-card-input"
                      value={selectedCard}
                      onChange={(e) => setSelectedCard(e.target.value)}
                    >
                      <option value="">Select Card</option>

                      {customerCards.map((c) => (
                        <option key={c.id} value={c.id}>
                          {c.model}
                        </option>
                      ))}
                    </select>
                  </div>
                )}

                <div className="createcard-input-cont">
                  <p>AMC Start Date *</p>
                  <input
                    type="date"
                    className="createcard-card-input"
                    onChange={(e) => setStartDate(e.target.value)}
                  />
                </div>

                <div className="createcard-input-cont">
                  <p>AMC End Date *</p>
                  <input
                    type="date"
                    className="createcard-card-input"
                    onChange={(e) => setEndDate(e.target.value)}
                  />
                </div>

                <div className="createcard-input-cont">
                  <p>Interval Months *</p>
                  <input
                    type="number"
                    min="1"
                    className="createcard-card-input"
                    value={intervalMonths}
                    onChange={(e) => setIntervalMonths(e.target.value)}
                  />
                </div>

              </div>

              <button
                className="createcard-card-button"
                onClick={createAMC}
              >
                Create Industrial AMC
              </button>

            </div>
          </div>

          <div className="createcard-r">
            <div className="createcard-img-cont">
              <img src={CreateCardimg} alt="" />
              <p>
                Industrial AMC supports custom service intervals.
              </p>
            </div>
          </div>

        </div>
      )}

      {/* ================= TABLE ================= */}

      {loading ? (
        <div className="loader-wrapper">
          <div className="loader" />
        </div>
      ) : (
        <div className="table-wrapper">
          <table className="amc-table">

            <thead>
              <tr>
                <th>Milestone</th>
                <th>Customer</th>
                <th>Phone</th>
                <th>City</th>
                <th>Status</th>
                <th>Scheduled Date</th>
                <th>Assign Staff</th>
                <th>Attendance</th>
              </tr>
            </thead>

            <tbody>
              {cards.map((card) => (
                <tr key={card.card_id}>

                  <td>{formatDate(card.milestone)}</td>
                  <td>{card.customer_name}</td>
                  <td>{card.customer_phone}</td>
                  <td>{card.city}</td>
                  <td>{card.status}</td>

                  <td>
                    <input
                      type="date"
                      value={scheduledDates[card.card_id] || ""}
                      disabled={card.status === "done"}
                      min={addDays(card.milestone, -20)}
                      max={addDays(card.milestone, 20)}
                      onChange={(e) =>
                        handleScheduledDateChange(
                          card.card_id,
                          e.target.value
                        )
                      }
                    />
                  </td>

                  <td>
                    <select
                      value={selectedStaff[card.card_id] || ""}
                      disabled={card.status === "done"}
                      onChange={(e) =>
                        handleStaffChange(card.card_id, e.target.value)
                      }
                    >
                      <option value="">None</option>
                      {staffList.map((s) => (
                        <option key={s.id} value={s.id}>
                          {s.name}
                        </option>
                      ))}
                    </select>
                  </td>

                  <td>
                    {selectedStaff[card.card_id] ? (
                      attendanceMap[selectedStaff[card.card_id]] === "present" ? (
                        <span className="attendance attendance-present">
                          Present
                        </span>
                      ) : (
                        <span className="attendance attendance-absent">
                          Absent
                        </span>
                      )
                    ) : (
                      <span>—</span>
                    )}
                  </td>

                </tr>
              ))}
            </tbody>

          </table>
        </div>
      )}
    </div>
  );
};

export default IndustrialAMC;
