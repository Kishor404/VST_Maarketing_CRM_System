import '../styles/reminder.css';
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import Cookies from 'js-cookie';
import { useParams } from "react-router-dom";

const Reminder = () => {

    const BASEURL = "http://157.173.220.208";
    const navigate = useNavigate();
    const [reminders, setReminders] = useState([]);

    const [reminderDates, setReminderDates] = useState([]);
    const [message, setMessage] = useState("");
    const [showCreatePopup, setShowCreatePopup] = useState(false);
    const [loadingCustomer, setLoadingCustomer] = useState(false);
    const [tempReminderDate, setTempReminderDate] = useState("");
    const [reminderCustomerPhone, setReminderCustomerPhone] = useState("");
    const [reminderCustomer, setReminderCustomer] = useState(null);
    const [selectedReminders, setSelectedReminders] = useState([]);

    const [reminderCustomerName, setReminderCustomerName] = useState("");
    const [isManualCustomer, setIsManualCustomer] = useState(false);


    // ============= API FUNCTIONS ================

    // ~~~~~~~~~~~~~ REFRESH TOKEN ~~~~~~~~~~~~~~~~

    const refresh_token = async () => {
        const rToken = Cookies.get('refresh_token');

        if (!rToken) {
            return null;
        }

        try {
            const res = await axios.post(BASEURL+'/api/auth/token/refresh/', 
                { 'refresh': rToken }, 
                { headers: { "Content-Type": "application/json" } }
            );
            Cookies.set('refresh_token', res.data.refresh, { expires: 7 });
            return res.data.access;
        } catch (error) {
            console.error("Error refreshing token:", error);
            return null;
        }
    };

    const localToUTC = (localDateTime) => {
        const localDate = new Date(localDateTime);
        return new Date(localDate.getTime() - localDate.getTimezoneOffset() * 60000).toISOString();
    };

    const utcToIST = (utcDateTime) => {
        return new Date(utcDateTime).toLocaleString("en-IN", {
            timeZone: "Asia/Kolkata",
            hour12: true
        });
    };

    // ~~~~~~~~~~~ GET ALL REMINDER ~~~~~~~~~~~~~~

    const getAllReminders=async()=>{
        const Token=await refresh_token();
        if(!Token){
            navigate('/head/');
            return null;
        }
        try {
            const res = await axios.get(BASEURL+`/api/reminder/admin-reminders/`, { headers: { Authorization: `Bearer ${Token}` } });
            console.log("GET ALL REMINDERS");
            console.log(res.data);
            setReminders(res.data);
        } catch (error) {
            console.error("Error in Get All Reminder:", error);
            return null;
        }
    }

    useEffect(()=>{
        getAllReminders();
    },[])

    const getUserByPhone = async (phone) => {
        const token = await refresh_token();
        if (!token) return null;

        try {
            const res = await axios.get(BASEURL+`/api/auth/admin/users/?phone=${phone}`, { headers: { Authorization: `Bearer ${token}` } });
            return res.data[0];
        } catch (error) {
            return null;
        }
    };

    const assignPhoneToCustomer = async (phone) => {

        if (phone.length === 10) {

            const user = await getUserByPhone(phone);

            if (user && user.role === "customer") {

                // Existing customer found
                setReminderCustomer(user);
                setReminderCustomerName(user.name);
                setIsManualCustomer(false);

            } else {

                // Manual entry mode
                setReminderCustomer(null);
                setReminderCustomerName("");
                setIsManualCustomer(true);
            }

        } else {

            setReminderCustomer(null);
            setReminderCustomerName("");
            setIsManualCustomer(false);
        }
    };





    // ~~~~~~~~~~ CREATE NEW REMINDER ~~~~~~~~~~~~~

    const postReminder=async(data)=>{
        const Token=await refresh_token();
        if(!Token){
            navigate('/head/');
            return null;
        }
        try {
            const reqData=data
            const res = await axios.post(BASEURL+`/api/reminder/admin-reminders/`, reqData, { headers: { Authorization: `Bearer ${Token}` } });
            console.log(res);
            console.log("POST REMINDER");
            alert("Reminder Created successfully!");
        } catch (error) {
            console.error("Error in Reminder:", error);
            alert("Error In Creating Reminder!");
            return null;
        }
    }

    const handleCreateReminder = async () => {

        if (reminderDates.length === 0 || !message) {
            alert("Reminder date and message required");
            return;
        }

        let data = {
            reminder_dates: reminderDates.map(d => d + "+05:30"),
            message: message,
            is_active: true
        };

        // If customer exists → use customer_id
        if (reminderCustomer) {

            data.customer_id = reminderCustomer.id;

        }
        // Else use name and phone
        else {

            if (!reminderCustomerName || !reminderCustomerPhone) {
                alert("Enter customer name and phone");
                return;
            }

            data.name = reminderCustomerName;
            data.phone = reminderCustomerPhone;
        }

        const confirmCreate = window.confirm("Create reminder?");
        if (!confirmCreate) return;

        await postReminder(data);

        // Reset
        setShowCreatePopup(false);
        setReminderCustomerPhone("");
        setReminderCustomerName("");
        setReminderCustomer(null);
        setReminderDates([]);
        setMessage("");
        setIsManualCustomer(false);

        getAllReminders();
    };


    const addReminderDate = () => {
        if (!tempReminderDate) return;

        if (reminderDates.includes(tempReminderDate)) {
            alert("This date is already added");
            return;
        }

        setReminderDates([...reminderDates, tempReminderDate]);
        setTempReminderDate("");
    };

    const removeReminderDate = (index) => {
        const updatedDates = reminderDates.filter((_, i) => i !== index);
        setReminderDates(updatedDates);
    };

    const toggleReminderSelect = (id) => {
        setSelectedReminders((prev) =>
            prev.includes(id)
                ? prev.filter((rid) => rid !== id)
                : [...prev, id]
        );
    };  

    const deleteReminder = async (id) => {
        const token = await refresh_token();
        if (!token) {
            navigate('/head/');
            return;
        }

        try {
            await axios.delete(
                `${BASEURL}/api/reminder/admin-reminders/${id}/`,
                { headers: { Authorization: `Bearer ${token}` } }
            );
        } catch (error) {
            console.error("Error deleting reminder:", error);
            throw error;
        }
    };
    const handleDeleteReminders = async () => {
        if (selectedReminders.length === 0) {
            alert("Select at least one reminder to delete");
            return;
        }

        const confirmDelete = window.confirm(
            `Delete ${selectedReminders.length} reminder(s)?`
        );

        if (!confirmDelete) return;

        try {
            for (const id of selectedReminders) {
                await deleteReminder(id);
            }

            alert("Reminder(s) deleted successfully");
            setSelectedReminders([]);
            getAllReminders(); // refresh table
        } catch {
            alert("Error deleting reminder(s)");
        }
    };



    // +++++++++++++ FRONTEND UI ++++++++++++++++

    return (
        <div className="reminder-main">
            {showCreatePopup && (
                <div className="reminder-popup-overlay">
                    <div className="reminder-popup">
                        <h3>Create Reminder</h3>

                        <p className='service-bottom-right-bottom-create-info-title'>
                            Customer :
                            {reminderCustomer
                                ? `${reminderCustomer.name} (${reminderCustomer.id})`
                                : isManualCustomer
                                    ? "Manual entry"
                                    : "Enter phone"}
                        </p>

                        <input
                            type="text"
                            placeholder="Enter Customer Phone"
                            className="service-bottom-right-bottom-create-info-input"
                            value={reminderCustomerPhone}
                            onChange={(e) => {
                                const phone = e.target.value.replace(/\D/g, "");
                                setReminderCustomerPhone(phone);
                                assignPhoneToCustomer(phone);
                            }}
                            maxLength={10}
                        />


                        {/* Show name input if manual mode */}
                        {isManualCustomer && (
                            <input
                                type="text"
                                placeholder="Enter Customer Name"
                                className="service-bottom-right-bottom-create-info-input"
                                value={reminderCustomerName}
                                onChange={(e) => setReminderCustomerName(e.target.value)}
                            />
                        )}



                        <label>Reminder Dates</label>

                        <div className="reminder-date-input">
                            <input
                                type="datetime-local"
                                value={tempReminderDate}
                                onChange={(e) => setTempReminderDate(e.target.value)}
                            />
                            <button type="button" onClick={addReminderDate}>
                                ADD
                            </button>
                        </div>

                        {reminderDates.length > 0 && (
                            <div className="reminder-date-list">
                                {reminderDates.map((d, i) => (
                                    <div className="reminder-date-chip" key={i}>
                                        <span>{new Date(d).toLocaleString()}</span>
                                        <button onClick={() => removeReminderDate(i)}>✕</button>
                                    </div>
                                ))}
                            </div>
                        )}


                        <label>Message</label>
                        <textarea
                            value={message}
                            onChange={(e) => setMessage(e.target.value)}
                        />

                        <div className="popup-actions">
                            <button
                                onClick={handleCreateReminder}
                                disabled={
                                    loadingCustomer ||
                                    reminderDates.length === 0 ||
                                    !message ||
                                    (
                                        !reminderCustomer &&
                                        (!reminderCustomerName || !reminderCustomerPhone)
                                    )
                                }
                            >
                                Create
                            </button>
                            <button onClick={() => setShowCreatePopup(false)}>Cancel</button>
                        </div>
                    </div>
                </div>
            )}

            <div className='reminder-topbar'>
                <p className='reminder-topbar-title'>REMINDERS</p>
                <div className='reminder-topbar-buttons'>
                    <button onClick={() => setShowCreatePopup(true)} >CREATE</button>
                    <button
                        onClick={handleDeleteReminders}
                        disabled={selectedReminders.length === 0}
                    >
                        DELETE
                    </button>
                </div>

            </div>
            <div className='reminder-table-cont'>
                <table className="reminder-table">
                    <thead>
                        <tr>
                            <th></th>
                            <th>ID</th>
                            <th>Customer Name</th>
                            <th>Customer ID</th>
                            <th>Phone</th>
                            <th>Message</th>
                            <th>Reminder Date</th>
                            <th>Status</th>
                            <th>Created At</th>
                        </tr>
                    </thead>

                    <tbody>
                        {reminders.length === 0 ? (
                            <tr>
                                <td colSpan="9" style={{ textAlign: "center" }}>
                                    No reminders found
                                </td>
                            </tr>
                        ) : (
                            reminders.map((item) => (
                                <tr key={item.id}>
                                    <td>
                                        <input
                                            type="checkbox"
                                            checked={selectedReminders.includes(item.id)}
                                            onChange={() => toggleReminderSelect(item.id)}
                                        />
                                    </td>
                                    <td>{item.id}</td>
                                    <td>{item.name || item.customer?.name || "—"}</td>

                                    <td>{item.customer?.id || "—"}</td>

                                    <td>{item.phone || item.customer?.phone || "—"}</td>
                                    <td>{item.message}</td>
                                    <td>
                                        {item.reminder_dates?.[0]
                                            ? new Date(item.reminder_dates[0]).toLocaleString()
                                            : "—"}
                                    </td>
                                    <td>{item.is_active ? "Active" : "Inactive"}</td>
                                    <td>{new Date(item.created_at).toLocaleString()}</td>
                                </tr>
                            ))
                        )}
                    </tbody>

                </table>
            </div>
        </div>
    );
};

export default Reminder;
