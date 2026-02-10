import "../styles/jobcard.css";
import React, { useState, useEffect } from "react";
import axios from "axios";
import Cookies from "js-cookie";
import { useNavigate } from "react-router-dom";

const JobCard = () => {

    const BASEURL = "http://157.173.220.208";
    const navigate = useNavigate();

    const [jobCards, setJobCards] = useState([]);
    const [filteredCards, setFilteredCards] = useState([]);

    const [searchQuery, setSearchQuery] = useState("");
    const [statusFilter, setStatusFilter] = useState("");

    const [selectedCard, setSelectedCard] = useState(null);
    const [editStatus, setEditStatus] = useState("");

    const [reinstallStaffPhone, setReinstallStaffPhone] = useState("");
    const [reinstallStaff, setReinstallStaff] = useState(null);

    const [loading, setLoading] = useState(false);

    // ================= TOKEN =================

    const refresh_token = async () => {
        const rToken = Cookies.get("refresh_token");
        if (!rToken) return null;

        try {
            const res = await axios.post(
                BASEURL + "/api/auth/token/refresh/",
                { refresh: rToken }
            );
            return res.data.access;
        } catch {
            return null;
        }
    };

    // ================= FETCH =================

    const fetchJobCards = async () => {
        const token = await refresh_token();
        if (!token) return navigate("/head/");

        try {
            setLoading(true);

            const res = await axios.get(
                `${BASEURL}/api/crm/job-cards/`,
                { headers: { Authorization: `Bearer ${token}` } }
            );

            setJobCards(res.data);
            setFilteredCards(res.data);
        } catch (err) {
            console.error(err);
        } finally {
            setLoading(false);
        }
    };

    // ================= PATCH =================

    const patchJobCard = async (id, data) => {
        const token = await refresh_token();
        if (!token) return navigate("/head/");

        try {
            await axios.patch(
                `${BASEURL}/api/crm/job-cards/${id}/`,
                data,
                { headers: { Authorization: `Bearer ${token}` } }
            );

            alert("Updated Successfully");
            fetchJobCards();
        } catch {
            alert("Update Failed");
        }
    };

    // ================= STAFF SEARCH =================

    const getUserByPhone = async (phone) => {
        const token = await refresh_token();
        if (!token) return null;

        try {
            const res = await axios.get(
                `${BASEURL}/api/auth/admin/users/?phone=${phone}`,
                { headers: { Authorization: `Bearer ${token}` } }
            );
            return res.data[0];
        } catch {
            return null;
        }
    };

    // ================= HANDLERS =================

    const handleSelectCard = (card) => {
        setSelectedCard(card);
        setEditStatus(card.status);
        setReinstallStaff(null);
        setReinstallStaffPhone("");
    };

    const handleUpdate = () => {
        if (!selectedCard) return;

        patchJobCard(selectedCard.id, {
            status: editStatus,
            reinstall_staff: reinstallStaff?.id || selectedCard.reinstall_staff
        });
    };

    const assignReinstallStaff = async (phone) => {
        if (phone.length < 10) return setReinstallStaff(null);

        const user = await getUserByPhone(phone);
        if (user) setReinstallStaff(user);
    };

    // ================= FILTER =================

    useEffect(() => {
        let list = jobCards;

        if (searchQuery) {
            list = list.filter(
                c =>
                    c.id.toString().includes(searchQuery) ||
                    c.part_name.toLowerCase().includes(searchQuery.toLowerCase())
            );
        }

        if (statusFilter) {
            list = list.filter(c => c.status === statusFilter);
        }

        setFilteredCards(list);

    }, [searchQuery, statusFilter, jobCards]);

    useEffect(() => {
        fetchJobCards();
    }, []);

    // ================= UI =================

    return (
        <div className="jobcard-main">

            {/* ================= LEFT LIST ================= */}
            <div className="jobcard-left">

                <div className="jobcard-search">
                    <input
                        placeholder="Search ID / Part"
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                    />

                    <select
                        value={statusFilter}
                        onChange={(e) => setStatusFilter(e.target.value)}
                    >
                        <option value="">All</option>
                        <option value="get_from_customer">Get From Customer</option>
                        <option value="received_office">Received Office</option>
                        <option value="repair_completed">Repair Completed</option>
                        <option value="reinstalled">Reinstalled</option>
                    </select>
                </div>

                {loading ? (
                    <p>Loading...</p>
                ) : (
                    <table className="jobcard-table">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Part</th>
                                <th>Status</th>
                                <th>Staff</th>
                            </tr>
                        </thead>

                        <tbody>
                            {filteredCards.map(card => (
                                <tr key={card.id}
                                    onClick={() => handleSelectCard(card)}>
                                    <td>{card.id}</td>
                                    <td>{card.part_name}</td>
                                    <td>{card.status}</td>
                                    <td>{card.staff_name || "-"}</td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>

            {/* ================= RIGHT PANEL ================= */}
            <div className="jobcard-right">

                {selectedCard ? (
                    <div className="jobcard-editor">

                        <h3>Job Card #{selectedCard.id}</h3>

                        <p><b>Service:</b> {selectedCard.service_id}</p>
                        <p><b>Service Status:</b> {selectedCard.service_status}</p>
                        <p><b>Part:</b> {selectedCard.part_name}</p>
                        <p><b>Details:</b> {selectedCard.details}</p>

                        {/* IMAGE */}
                        {selectedCard.image_url && (
                            <img
                                src={selectedCard.image_url}
                                alt="job"
                                className="jobcard-image"
                            />
                        )}

                        {/* TIMELINE */}
                        <div className="jobcard-timeline">
                            <p>Received: {selectedCard.received_office_at || "-"}</p>
                            <p>Repair Done: {selectedCard.repair_completed_at || "-"}</p>
                            <p>Reinstalled: {selectedCard.reinstalled_at || "-"}</p>
                        </div>

                        {/* STATUS */}
                        <label>Status</label>
                        <select
                            value={editStatus}
                            onChange={(e) => setEditStatus(e.target.value)}
                        >
                            <option value="get_from_customer">Get From Customer</option>
                            <option value="received_office">Received Office</option>
                            <option value="repair_completed">Repair Completed</option>
                            <option value="reinstalled">Reinstalled</option>
                        </select>

                        {/* REINSTALL STAFF */}
                        <label>Assign Reinstall Staff</label>
                        <input
                            placeholder="Enter Phone"
                            value={reinstallStaffPhone}
                            onChange={(e) => {
                                setReinstallStaffPhone(e.target.value);
                                assignReinstallStaff(e.target.value);
                            }}
                        />

                        {reinstallStaff && (
                            <p className="jobcard-staff">
                                {reinstallStaff.name} (ID {reinstallStaff.id})
                            </p>
                        )}

                        <button onClick={handleUpdate}>
                            Update Job Card
                        </button>

                    </div>
                ) : (
                    <p className="jobcard-empty">Select Job Card</p>
                )}

            </div>
        </div>
    );
};

export default JobCard;
