// src/pages/IndustrialAMC.jsx

import React, { useState, useEffect } from "react";
import api from "../api/axiosInstance";
import "../styles/amc.css";
import "../styles/industrial_amc.css";
import "../styles/createcard.css";

import * as XLSX from "xlsx";
import { saveAs } from "file-saver";

/* ---------------- PAGE ---------------- */

const IndustrialAMC = () => {

  /* ---------- STATES ---------- */

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [searchMode, setSearchMode] = useState("phone");

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
  const [intervalDays, setIntervalDays] = useState(120);

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

  useEffect(() => {
    document.body.style.overflow = showCreateAMC ? "hidden" : "auto";
  }, [showCreateAMC]);


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
      Interval: card.interval_days + " days",
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

  const getCustomer = async (value) => {

    if (!value) {
      setCustomer(null);
      return;
    }

    try {

      let url = "";

      if (searchMode === "phone") {

        if (value.length !== 10) {
          setCustomer(null);
          return;
        }

        url = `/auth/admin/users/?phone=${value}&role=customer`;
      }

      if (searchMode === "customer_code") {
        url = `/auth/admin/users/?customer_code=${value}`;
      }

      const res = await api.get(url);

      if (res.data.length > 0) {

        const user = res.data[0];

        // ⭐ Industrial validation
        if (!user.is_industrial) {
          alert("Customer is NOT Industrial");
          setCustomer(null);
          return;
        }

        setCustomer(user);
        fetchCustomerCards(user.id);

      } else {
        setCustomer(null);
        setCustomerCards([]);
      }

    } catch (error) {
      console.error(error);
      setCustomer(null);
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

    if (!selectedCard || !startDate || !endDate || !intervalDays){
      alert("Fill all fields");
      return;
    }

    if (!window.confirm("Create Industrial AMC?")) return;

    try {

      await api.post(`/crm/industrial-amc/`, {
        card: selectedCard,
        start_date: startDate,
        end_date: endDate,
        interval_days: Number(intervalDays),
      });


      alert("Industrial AMC Created");

      setShowCreateAMC(false);
      fetchIndustrialAMC(selectedMonth);

    } catch (err) {
      console.error(err);
      alert("Failed to create Industrial AMC");
    }
  };

  const getRowBgClass = (status) => {
    if (status === "done") return "iamc-row-done";
    return "iamc-row-notdone";
  };

  /* ---------------- UI ---------------- */

  return (
    <div className="iamc-container">

      {error && <div className="alert alert-error">{error}</div>}

      {/* ================= CONTROLS ================= */}

      <div className="iamc-controls-row">

        <h2 className="iamc-title">Industrial AMC Services</h2>

        <div className="iamc-form-form">

          <select
            className="iamc-form-select"
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
            className="iamc-btn btn-warning"
            onClick={() => setShowCreateAMC(!showCreateAMC)}
          >
            {showCreateAMC ? "Close Create AMC" : "Create Industrial AMC"}
          </button>

          <button
            className="iamc-btn btn-primary"
            onClick={handleBulkBook}
            disabled={bulkBooking}
          >
            {bulkBooking ? "Booking..." : "Bulk Book"}
          </button>

          <button className="iamc-btn btn-secondary" onClick={exportExcel}>
            Export Excel
          </button>

        </div>
      </div>

      {/* ================= CREATE AMC PANEL ================= */}

      {showCreateAMC && (
        <div className="iamc-modal-overlay" onClick={() => setShowCreateAMC(false)}>

          <div className="iamc-modal-content" onClick={(e) => e.stopPropagation()}>

            <button
              className="iamc-modal-close"
              onClick={() => setShowCreateAMC(false)}
            >
              ✕
            </button>

            <div className="iamc-createcard-card">

              <p className="iamc-createcard-title">Create Industrial AMC</p>

              <div className="iamc-createcard-inputs">

                <div className="iamc-createcard-input-cont">
                  <p>
                    Customer :
                      {customer
                        ? ` ${customer.name} (${customer.customer_code})`
                        : " Not Found"
                      }

                  </p>

                  <select
                    className="iamc-createcard-card-input-io"
                    value={searchMode}
                    onChange={(e) => {
                      setSearchMode(e.target.value);
                      setCustomer(null);
                      setCustomerCards([]);
                    }}
                  >
                    <option value="phone">Search By Phone</option>
                    <option value="customer_code">Search By Customer Code</option>
                  </select>

                  <input
                    className="iamc-createcard-card-input"
                    placeholder={
                      searchMode === "phone"
                        ? "Enter Customer Phone"
                        : "Enter Customer Code"
                    }
                    onChange={(e) => getCustomer(e.target.value)}
                  />

                </div>

                {customer && (
                  <div className="iamc-createcard-input-cont">
                    <p>Select Card *</p>

                    <select
                      className="iamc-createcard-card-input"
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

                <div className="iamc-createcard-input-cont">
                  <p>AMC Start Date *</p>
                  <input
                    type="date"
                    className="iamc-createcard-card-input"
                    onChange={(e) => setStartDate(e.target.value)}
                  />
                </div>

                <div className="iamc-createcard-input-cont">
                  <p>AMC End Date *</p>
                  <input
                    type="date"
                    className="iamc-createcard-card-input"
                    onChange={(e) => setEndDate(e.target.value)}
                  />
                </div>

                <div className="iamc-createcard-input-cont">
                  <p>Interval Days *</p>
                  <input
                    type="number"
                    min="1"
                    className="iamc-createcard-card-input"
                    value={intervalDays}
                    onChange={(e) => setIntervalDays(e.target.value)}
                  />

                </div>

              </div>

              <button
                className="iamc-createcard-card-button"
                onClick={createAMC}
              >
                Create Industrial AMC
              </button>

            </div>
          </div>
          </div>
      )}

      {/* ================= TABLE ================= */}

      {loading ? (
        <div className="iamc-loader-wrapper">
          <div className="iamc-loader" />
        </div>
      ) : (
        <div className="iamc-table-wrapper">
          <table className="iamc-table">

            <thead>
              <tr>
                <th>Milestone</th>
                <th>All Milestones</th>
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
                <tr
                  key={card.card_id}
                  className={getRowBgClass(card.status)}
                >


                  <td>{formatDate(card.milestone)}</td>

                  <td>
                    {card.allmilestones?.length ? (
                      <ul className="milestone-list">
                        {card.allmilestones.map((m, i) => (
                          <li key={i}>{formatDate(m)}</li>
                        ))}
                      </ul>
                    ) : (
                      <span>—</span>
                    )}
                  </td>

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
                        <span className="iamc-attendance attendance-present">
                          Present
                        </span>
                      ) : (
                        <span className="iamc-attendance attendance-absent">
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
