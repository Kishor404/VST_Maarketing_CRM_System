// src/pages/Warranty.jsx
import React, { useState, useEffect } from 'react';
import api from '../api/axiosInstance';
import '../styles/warranty.css';
import * as XLSX from 'xlsx';
import { saveAs } from 'file-saver';

const Warranty = () => {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [cards, setCards] = useState([]);
  const [selectedMonth, setSelectedMonth] = useState('');
  const [staffList, setStaffList] = useState([]);
  const [selectedStaff, setSelectedStaff] = useState({});
  const [bulkBooking, setBulkBooking] = useState(false);
  const [attendanceMap, setAttendanceMap] = useState({});
  const [scheduledDates, setScheduledDates] = useState({});

  const addDays = (dateStr, days) => {
    const d = new Date(dateStr);
    d.setDate(d.getDate() + days);
    return d.toISOString().split('T')[0];
  };

  function formatDate(dateInput) {
    const date = new Date(dateInput);

    if (isNaN(date)) return null;

    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();

    return `${day}/${month}/${year}`;
  }



  const generateMonthOptions = () => {
    const options = [];
    const now = new Date();

    for (let offset = -3; offset <= 9; offset++) {
      const d = new Date(now.getFullYear(), now.getMonth() + offset, 1);

      const value = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;

      const label = d.toLocaleString('default', { month: 'long', year: 'numeric' });

      options.push({ value, label });
    }

    return options;
  };


  const monthOptions = generateMonthOptions();

  const fetchWarrantyCards = async (month) => {
    setLoading(true);
    setError('');
    try {
      const res = await api.get(`/crm/reports/warranty/`, {
        params: { month },
      });
      console.log(res.data);
      setCards(res.data);
      console.log(res.data);
      const defaults = {};
      const staffDefaults = {};
      res.data.forEach((card) => {
        if (card.status === 'done' && card.scheduled_date) {
          // ✅ use actual service date
          defaults[card.card_id] = card.scheduled_date;
        } else if (card.milestone) {
          defaults[card.card_id] = card.milestone;
        }

        if (card.status === 'done' && card.staff) {
          staffDefaults[card.card_id] = card.staff.staff_id;
        }
      });
      setScheduledDates(defaults);
      setSelectedStaff(staffDefaults);

    } catch (err) {
      setError('Failed to load warranty customers. Please try again.');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const fetchStaffList = async () => {
    try {
      const res = await api.get('/auth/admin/users/', {
        params: { role: 'worker' },
      });
      setStaffList(res.data);
    } catch (err) {
      console.error('Failed to load staff:', err);
    }
  };

  const fetchTodayAttendance = async () => {
    const today = new Date().toISOString().split('T')[0];
    try {
      const res = await api.get('/crm/attendance/by_date/', {
        params: { date: today },
      });
      const map = {};
      res.data.records.forEach((r) => {
        map[r.user_id] = r.status;
      });
      setAttendanceMap(map);
    } catch (err) {
      console.error('Failed to fetch today attendance', err);
    }
  };

  useEffect(() => {
    const now = new Date();
    const currentMonth = `${now.getFullYear()}-${String(
      now.getMonth() + 1
    ).padStart(2, '0')}`;
    setSelectedMonth(currentMonth);
    fetchWarrantyCards(currentMonth);
    fetchStaffList();
    fetchTodayAttendance();
  }, []);

  const handleMonthChange = (e) => {
    const month = e.target.value;
    setSelectedMonth(month);
    fetchWarrantyCards(month);
  };

  const exportWarrantyExcel = () => {
    if (!cards.length) {
      alert('No data to export');
      return;
    }

    const data = cards.map((card, index) => ({
      'S.No': index + 1,
      Milestone: formatDate(card.milestone) || '',
      customer_id: card.customer_id || '',
      Customer: card.customer_name || '',
      Phone: card.customer_phone || '',
      Address: card.address || '',
      'Card Model': card.card_model || '',
      City: card.city || '',
      Status: card.status || '',

      'Scheduled Date': formatDate(
        card.status === 'done' && card.scheduled_date
          ? card.scheduled_date
          : scheduledDates[card.card_id]
      ) || '',

      'Assign Staff':
        card.status === 'done' && card.staff
          ? card.staff.staff_name
          : staffList.find((s) => s.id === selectedStaff[card.card_id])?.name || '',

      'Attendance (Today)':
        selectedStaff[card.card_id]
          ? attendanceMap[selectedStaff[card.card_id]] || '—'
          : '—',
    }));


    const worksheet = XLSX.utils.json_to_sheet(data, {
      cellDates: true,
    });

    const workbook = XLSX.utils.book_new();
    XLSX.utils.book_append_sheet(workbook, worksheet, 'Warranty');

    const buffer = XLSX.write(workbook, {
      bookType: 'xlsx',
      type: 'array',
    });

    const blob = new Blob([buffer], {
      type:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });

    saveAs(blob, `Warranty_Customers_${selectedMonth}.xlsx`);
  };





  const handleStaffChange = (cardId, staffId) => {
    setSelectedStaff((prev) => {
      const updated = { ...prev };
      if (!staffId) {
        delete updated[cardId];
      } else {
        updated[cardId] = staffId;
      }
      return updated;
    });
  };

  const getRowBgClass = (status) => {
    if (status === 'done') return 'row-done';
    if (status === 'notdone') return 'row-notdone';
    return '';
  };

  const handleScheduledDateChange = (cardId, value) => {
    setScheduledDates((prev) => ({
      ...prev,
      [cardId]: value,
    }));
  };

  const handleBulkBook = async () => {
    const confirmed = window.confirm(
      'Are you sure you want to bulk book services for selected customers?'
    );
    if (!confirmed) return;

    if (cards.length === 0) return;

    for (const card of cards) {
      if (selectedStaff[card.card_id] && !scheduledDates[card.card_id]) {
        setError('Scheduled date is mandatory for all selected services.');
        setBulkBooking(false);
        return;
      }
    }

    setBulkBooking(true);
    setError('');

    try {
      const bookingPromises = cards
        .filter((card) => selectedStaff[card.card_id])
        .map(async (card) => {
          const staffId = selectedStaff[card.card_id];

          const payload = {
            card: card.card_id,
            description: 'Free service under warranty',
            service_type: 'free',
            preferred_date: scheduledDates[card.card_id] || null,
            scheduled_at: scheduledDates[card.card_id] || null,
            visit_type: 'MS',
            requested_by: card.customer_id,
            assigned_to: staffId,
          };

          try {
            console.log(payload);
            await api.post('/crm/services/admin_create/', payload);
            return { cardId: card.card_id, success: true };
          } catch (err) {
            return { cardId: card.card_id, success: false };
          }
        });

      if (bookingPromises.length === 0) {
        setError('No staff selected for bulk booking.');
        setBulkBooking(false);
        return;
      }

      const results = await Promise.all(bookingPromises);
      const failed = results.filter((r) => !r.success);

      if (failed.length > 0) {
        setError(
          `Successfully booked ${results.length - failed.length} services. ${failed.length} failed.`
        );
      } else {
        setError('All services booked successfully!');
      }

      fetchWarrantyCards(selectedMonth);
    } catch (err) {
      setError('Bulk booking failed. Please try again.');
    } finally {
      setBulkBooking(false);
    }
  };

  return (
    <div className="warranty-container">
      

      {error && (
        <div
          className={`alert ${
            error.includes('successfully') ? 'alert-success' : 'alert-error'
          }`}
        >
          {error}
        </div>
      )}

      <div className="controls-row">
        <h2 className="warranty-title">
          Warranty Customers - Free Service Booking
        </h2>

        <div className='form-form'>

          <div className="form-control">
          <select
            id="month-select"
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
        </div>

        <button
          className="btn btn-primary"
          onClick={handleBulkBook}
          disabled={loading || bulkBooking || cards.length === 0}
        >
          {bulkBooking ? 'Booking...' : 'Bulk Book'}
        </button>

        <button
          className="btn btn-secondary"
          onClick={exportWarrantyExcel}
          disabled={loading || cards.length === 0}
        >
          Export Excel
        </button>



        </div>
        
      </div>

      {loading ? (
        <div className="loader-wrapper">
          <div className="loader" />
        </div>
      ) : (
        <div className="table-wrapper">
          <table className="warranty-table">
            <thead>
              <tr>
                <th>Milestone</th>
                <th>All Milestone</th>
                <th>Customer ID</th>
                <th>Customer</th>
                <th>Phone</th>
                <th>Card Model</th>
                <th>City</th>
                <th>Status</th>
                <th>Scheduled Date</th>
                <th>Assign Staff</th>
                <th>Attendance (Today)</th>
              </tr>
            </thead>
            <tbody>
              {cards.length === 0 ? (
                <tr>
                  <td colSpan={10} className="empty-row">
                    No warranty customers found for this month.
                  </td>
                </tr>
              ) : (
                cards.map((card) => (
                  <tr
                    key={card.card_id}
                    className={getRowBgClass(card.status)}
                  >
                    <td>{formatDate(card.milestone)}</td>
                    <td>
                      {card.allmilestones?.length ? (
                        <ul className="milestone-list">
                          {card.allmilestones.map((mi, i) => (
                            <li key={i}>{formatDate(mi)}</li>
                          ))}
                        </ul>
                      ) : (
                        <span>—</span>
                      )}
                    </td>

                    <td>{card.customer_id}</td>
                    <td>{card.customer_name}</td>
                    <td>{card.customer_phone}</td>
                    <td>{card.card_model}</td>
                    <td>{card.city}</td>
                    <td>{card.status}</td>
                    <td>
                    {card.milestone ? (
                      <input
                        type="date"
                        className="date-input"
                        value={scheduledDates[card.card_id] || ''}
                        disabled={card.status === 'done'}   // ✅ lock completed services
                        min={addDays(card.milestone, -20)}
                        max={addDays(card.milestone, 20)}
                        onChange={(e) =>
                          handleScheduledDateChange(card.card_id, e.target.value)
                        }
                      />

                    ) : (
                      <span>—</span>
                    )}
                  </td>
                    <td>
                      <select
                        className="form-select"
                        value={selectedStaff[card.card_id] || ''}
                        disabled={card.status === 'done'}   // ✅ lock if done
                        onChange={(e) =>
                          handleStaffChange(card.card_id, e.target.value)
                        }
                      >
                        <option value="">None</option>
                        {staffList.map((staff) => (
                          <option key={staff.id} value={staff.id}>
                            {staff.name}
                          </option>
                        ))}
                      </select>

                    </td>
                    <td>
                      {selectedStaff[card.card_id] ? (
                        attendanceMap[selectedStaff[card.card_id]] ===
                        'present' ? (
                          <span className="attendance attendance-present">
                            Present
                          </span>
                        ) : (
                          <span className="attendance attendance-absent">
                            Absent
                          </span>
                        )
                      ) : (
                        <span className="attendance attendance-none">—</span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};

export default Warranty;
