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
  const [totals, setTotals] = useState({});
  const [selectedMonth, setSelectedMonth] = useState('');
  const [staffList, setStaffList] = useState([]);
  const [selectedStaff, setSelectedStaff] = useState({});
  const [bulkBooking, setBulkBooking] = useState(false);
  const [attendanceMap, setAttendanceMap] = useState({});
  const [scheduledDates, setScheduledDates] = useState({});
  const [bookSelection, setBookSelection] = useState({});

  const [selectedService, setSelectedService] = useState(null);
  const [showServiceModal, setShowServiceModal] = useState(false);
  const [editingService, setEditingService] = useState(false);
  const [savingService, setSavingService] = useState(false);

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

      const reportData = res.data.report_data || [];
      const summaryTotals = res.data.summary_totals || {};
      console.log(res.data);
      setCards(reportData);
      setTotals(summaryTotals);
      const defaults = {};
      const staffDefaults = {};
      const bookingDefaults = {};
      reportData.forEach((card) => {
        if (
          (
            card.status === 'done' ||
            card.status === 'BookedButNotCompleted'
          ) &&
          card.scheduled_date
        ) {
          defaults[card.card_id] = card.scheduled_date;
        } else if (card.milestone) {
          defaults[card.card_id] = card.milestone;
        }

        if (
          (
            card.status === 'done' ||
            card.status === 'BookedButNotCompleted'
          ) &&
          card.staff
        ) {
          staffDefaults[card.card_id] = card.staff.staff_id;
        }

        if (
          card.status === 'done' ||
          card.status === 'BookedButNotCompleted'
        ) {
          bookingDefaults[card.card_id] = false;
        } else {
          bookingDefaults[card.card_id] = true;
        }
      });
      setScheduledDates(defaults);
      setSelectedStaff(staffDefaults);
      setBookSelection(bookingDefaults);

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

  const handleBookToggle = (cardId) => {
    setBookSelection((prev) => ({
      ...prev,
      [cardId]: !prev[cardId],
    }));
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
      Note:card.warranty_note || '',
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


    // Add title row
    const worksheet = XLSX.utils.aoa_to_sheet([
      ['Domestic Warranty'], // Title Row
      [], // Empty Row
    ]);

    // Add data starting from row 3
    XLSX.utils.sheet_add_json(worksheet, data, {
      origin: 'A3',
    });

    worksheet['!merges'] = [
      {
        s: { r: 0, c: 0 }, // Start A1
        e: { r: 0, c: 12 }, // End M1 (adjust according to your column count)
      },
    ];

    // Optional: Set column width for title visibility
    worksheet['A1'].s = {
      font: { bold: true, sz: 16 },
      alignment: { horizontal: 'center' },
    };

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
    if (status === 'done') {
      return 'row-done';
    }

    if (status === 'BookedButNotCompleted') {
      return 'row-booked';
    }

    if (status === 'notdone') {
      return 'row-notdone';
    }

    return '';
  };

  const handleScheduledDateChange = (cardId, value) => {
    setScheduledDates((prev) => ({
      ...prev,
      [cardId]: value,
    }));
  };

  const handleWarrantyClick = (card) => {
    if (
      card.status !== 'done' &&
      card.status !== 'BookedButNotCompleted'
    ) {
      return;
    }

    if (!card.service) {
      return;
    }

    setSelectedService({
      ...card.service,
      customer_name: card.customer_name,
      customer_phone: card.customer_phone,
      card_model: card.card_model,
      warranty_note: card.warranty_note,
      milestone: card.milestone,
    });

    setEditingService(false);
    setShowServiceModal(true);
  };

  const handleEditService = () => {
    if (!selectedService) return;

    setEditingService(true);
  };

  const handleSaveService = async () => {
    if (!selectedService?.id) return;

    setSavingService(true);

    try {
      await api.patch(
        `/crm/services/${selectedService.id}/`,
        {
          status: selectedService.status,
          description: selectedService.description,
          service_type: selectedService.service_type,
          scheduled_at: selectedService.scheduled_at,
          assigned_to: selectedService.assigned_to,
        }
      );

      setError('Service updated successfully!');

      setEditingService(false);
      setShowServiceModal(false);

      await fetchWarrantyCards(selectedMonth);

    } catch (err) {
      console.error(err);

      setError(
        err.response?.data?.detail ||
        'Failed to update service.'
      );
    } finally {
      setSavingService(false);
    }
  };

  const handleDeleteService = async () => {
    if (!selectedService?.id) return;

    const confirmed = window.confirm(
      'Are you sure you want to delete this warranty service?'
    );

    if (!confirmed) {
      return;
    }

    try {
      await api.delete(
        `/crm/services/${selectedService.id}/`
      );

      setError('Warranty service deleted successfully!');

      setSelectedService(null);
      setShowServiceModal(false);

      await fetchWarrantyCards(selectedMonth);

    } catch (err) {
      console.error(err);

      setError(
        err.response?.data?.detail ||
        'Failed to delete warranty service.'
      );
    }
  };

  const handleBulkBook = async () => {
    const confirmed = window.confirm(
      'Are you sure you want to bulk book services for selected customers?'
    );
    if (!confirmed) return;

    if (cards.length === 0) return;

    for (const card of cards) {
      if (
        bookSelection[card.card_id] &&
        selectedStaff[card.card_id] &&
        !scheduledDates[card.card_id]
      ) {
        setError('Scheduled date is mandatory for all selected services.');
        setBulkBooking(false);
        return;
      }
    }

    setBulkBooking(true);
    setError('');

    try {
      const bookingPromises = cards
        .filter((card) => bookSelection[card.card_id] && selectedStaff[card.card_id] && card.status !== "done")
        .map(async (card) => {
          const staffId = selectedStaff[card.card_id];

          const payload = {
            card: card.card_id,
            description: 'Warranty Service - '+card.warranty_note,
            service_type: 'free',
            preferred_date: scheduledDates[card.card_id] || null,
            scheduled_at: scheduledDates[card.card_id] || null,
            visit_type: 'MS',
            requested_by: card.customer_id,
            assigned_to: staffId,
            is_warranty_service: true,
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
          Warranty Customers
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

      {/* --- NEW SUMMARY SECTION --- */}
      {!loading && cards.length > 0 && (
        <div className="summary-section">
          <div className="summary-card"><strong>Spun:</strong> {totals.spun_filter}</div>
          <div className="summary-card"><strong>Pre Carbon:</strong> {totals.pre_carbon}</div>
          <div className="summary-card"><strong>Sediment:</strong> {totals.sediments}</div>
          <div className="summary-card"><strong>Post Carbon:</strong> {totals.post_carbon}</div>
        </div>
      )}

      {loading ? (
        <div className="loader-wrapper">
          <div className="loader" />
        </div>
      ) : (
        <div className="table-wrapper">
          <table className="warranty-table">
            <thead>
              <tr>
                <th>Book?</th>
                <th>Milestone</th>
                <th>Note</th>
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
                    className={`${getRowBgClass(card.status)} ${
                      card.service ? 'warranty-clickable-row' : ''
                    }`}
                    onClick={() => handleWarrantyClick(card)}
                  >
                    <td>
                      <label className="switch">
                        <input
                          type="checkbox"
                          checked={bookSelection[card.card_id] || false}
                          disabled={
                            card.status === "done" ||
                            card.status === "BookedButNotCompleted"
                          }
                          onClick={(e) => e.stopPropagation()}
                          onChange={() => handleBookToggle(card.card_id)}
                        />
                        <span className="slider"></span>
                      </label>
                    </td>
                    <td>{formatDate(card.milestone)}</td>
                    <td>{card.warranty_note?card.warranty_note:"None"}</td>
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
                    <td>
                      {card.status === 'done' && (
                        <span className="warranty-status warranty-status-done">
                          Completed
                        </span>
                      )}

                      {card.status === 'BookedButNotCompleted' && (
                        <span className="warranty-status warranty-status-booked">
                          Booked But Not Completed
                        </span>
                      )}

                      {card.status === 'notdone' && (
                        <span className="warranty-status warranty-status-notdone">
                          Not Booked
                        </span>
                      )}
                    </td>
                    <td>
                    {card.milestone ? (
                      <input
                        type="date"
                        className="date-input"
                        value={scheduledDates[card.card_id] || ''}
                        disabled={
                          card.status === 'done' ||
                          card.status === 'BookedButNotCompleted'
                        }
                        min={addDays(card.milestone, -20)}
                        max={addDays(card.milestone, 20)}
                        onClick={(e) => e.stopPropagation()}
                        onChange={(e) =>
                          handleScheduledDateChange(
                            card.card_id,
                            e.target.value
                          )
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
                        disabled={
                          card.status === 'done' ||
                          card.status === 'BookedButNotCompleted'
                        }
                        onClick={(e) => e.stopPropagation()}
                        onChange={(e) =>
                          handleStaffChange(
                            card.card_id,
                            e.target.value
                          )
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
      {showServiceModal && selectedService && (
        <div
          className="service-modal-overlay"
          onClick={() => {
            setShowServiceModal(false);
            setEditingService(false);
          }}
        >
          <div
            className="service-modal"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="service-modal-header">
              <h3>
                Warranty Service #{selectedService.id}
              </h3>

              <button
                className="modal-close-btn"
                onClick={() => {
                  setShowServiceModal(false);
                  setEditingService(false);
                }}
              >
                ×
              </button>
            </div>

            <div className="service-modal-body">

              <div className="service-info-grid">

                <div>
                  <label>Customer</label>
                  <strong>
                    {selectedService.customer_name}
                  </strong>
                </div>

                <div>
                  <label>Phone</label>
                  <strong>
                    {selectedService.customer_phone}
                  </strong>
                </div>

                <div>
                  <label>Card Model</label>
                  <strong>
                    {selectedService.card_model}
                  </strong>
                </div>

                <div>
                  <label>Warranty</label>
                  <strong>
                    {selectedService.warranty_note}
                  </strong>
                </div>

              </div>

              <div className="service-form">

                <div className="form-group">
                  <label>Status</label>

                  {editingService ? (
                    <select
                      value={selectedService.status || ''}
                      onChange={(e) =>
                        setSelectedService({
                          ...selectedService,
                          status: e.target.value,
                        })
                      }
                    >
                      <option value="pending">
                        Pending
                      </option>

                      <option value="scheduled">
                        Scheduled
                      </option>

                      <option value="assigned">
                        Assigned
                      </option>

                      <option value="in_progress">
                        In Progress
                      </option>

                      <option value="awaiting_otp">
                        Awaiting OTP
                      </option>

                      <option value="completed">
                        Completed
                      </option>

                      <option value="cancelled">
                        Cancelled
                      </option>

                      <option value="job_card_pending">
                        Job Card Pending
                      </option>

                      <option value="components_pending">
                        Components Pending
                      </option>
                    </select>
                  ) : (
                    <div className="service-value">
                      {selectedService.status}
                    </div>
                  )}
                </div>


                <div className="form-group">
                  <label>Scheduled Date</label>

                  {editingService ? (
                    <input
                      type="date"
                      value={
                        selectedService.scheduled_at || ''
                      }
                      onChange={(e) =>
                        setSelectedService({
                          ...selectedService,
                          scheduled_at: e.target.value,
                        })
                      }
                    />
                  ) : (
                    <div className="service-value">
                      {formatDate(
                        selectedService.scheduled_at
                      )}
                    </div>
                  )}
                </div>


                <div className="form-group">
                  <label>Assigned Staff</label>

                  {editingService ? (
                    <select
                      value={
                        selectedService.assigned_to || ''
                      }
                      onChange={(e) =>
                        setSelectedService({
                          ...selectedService,
                          assigned_to: e.target.value
                            ? Number(e.target.value)
                            : null,
                        })
                      }
                    >
                      <option value="">
                        None
                      </option>

                      {staffList.map((staff) => (
                        <option
                          key={staff.id}
                          value={staff.id}
                        >
                          {staff.name}
                        </option>
                      ))}
                    </select>
                  ) : (
                    <div className="service-value">
                      {selectedService.assigned_to_name ||
                        'Not Assigned'}
                    </div>
                  )}
                </div>


                <div className="form-group">
                  <label>Description</label>

                  {editingService ? (
                    <textarea
                      value={
                        selectedService.description || ''
                      }
                      onChange={(e) =>
                        setSelectedService({
                          ...selectedService,
                          description: e.target.value,
                        })
                      }
                    />
                  ) : (
                    <div className="service-description">
                      {selectedService.description ||
                        'No description'}
                    </div>
                  )}
                </div>

              </div>
            </div>


            <div className="service-modal-footer">

              {!editingService ? (
                <>
                  <button
                    className="btn btn-danger"
                    onClick={handleDeleteService}
                  >
                    Delete
                  </button>

                  <button
                    className="btn btn-primary"
                    onClick={handleEditService}
                  >
                    Edit
                  </button>
                </>
              ) : (
                <>
                  <button
                    className="btn btn-secondary"
                    onClick={() => {
                      setEditingService(false);
                    }}
                    disabled={savingService}
                  >
                    Cancel
                  </button>

                  <button
                    className="btn btn-primary"
                    onClick={handleSaveService}
                    disabled={savingService}
                  >
                    {savingService
                      ? 'Saving...'
                      : 'Save Changes'}
                  </button>
                </>
              )}

            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Warranty;
