import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import '../styles/showcard.css';
import { FaAddressCard } from "react-icons/fa";
import axios from 'axios';
import Cookies from 'js-cookie';
import * as XLSX from 'xlsx';
import { saveAs } from 'file-saver';


const BASEURL = "http://157.173.220.208";

const ShowCard = () => {

    const navigate = useNavigate();

    /* ---------------- AUTH CHECK ---------------- */
    useEffect(() => {
        const isLoggedIn = Cookies.get('Login') === 'True';
        if (!isLoggedIn) navigate('/head/');
    }, [navigate]);

    /* ---------------- STATE ---------------- */
    const [search, setSearch] = useState("");
    const [searchBy, setSearchBy] = useState("name"); // name | phone
    const [sortBy, setSortBy] = useState("latest");

    const [cardList, setCardList] = useState([]);
    const [selectedCard, setSelectedCard] = useState(null);

    /* ---------------- REFRESH TOKEN ---------------- */
    const refresh_token = async () => {
        const rToken = Cookies.get('refresh_token');
        try {
            const res = await axios.post(
                BASEURL + '/api/auth/token/refresh/',
                { refresh: rToken },
                { headers: { "Content-Type": "application/json" } }
            );
            Cookies.set('refresh_token', res.data.refresh, { expires: 7 });
            return res.data.access;
        } catch (error) {
            console.error("Error refreshing token:", error);
            return null;
        }
    };

    /* ---------------- FETCH ALL CARDS ---------------- */
    useEffect(() => {
        const fetchCards = async () => {
            const accessToken = await refresh_token();
            if (!accessToken) return;

            try {
                const res = await axios.get(
                    BASEURL + "/api/crm/cards/",
                    { headers: { Authorization: `Bearer ${accessToken}` } }
                );
                setCardList(res.data);
            } catch (error) {
                console.error("Error fetching cards:", error);
            }
        };

        fetchCards();
    }, []);

    /* ---------------- DELETE CARD (ADMIN) ---------------- */
    const deleteCard = async () => {
        if (!selectedCard) return;

        const confirmDelete = window.confirm(
            "⚠️ Are you sure you want to DELETE this card?\nThis action cannot be undone."
        );
        if (!confirmDelete) return;

        const accessToken = await refresh_token();
        if (!accessToken) return;

        try {
            await axios.delete(
                `${BASEURL}/api/crm/cards/${selectedCard.id}/admin-delete/`,
                { headers: { Authorization: `Bearer ${accessToken}` } }
            );

            alert("Card deleted successfully");

            // remove from list without reload
            setCardList(prev => prev.filter(c => c.id !== selectedCard.id));
            setSelectedCard(null);

        } catch (error) {
            console.error("Delete failed:", error);

            const msg =
                error.response?.data?.detail ||
                "Failed to delete card (active services may exist)";
            alert(msg);
        }
    };


    /* ---------------- FETCH SINGLE CARD ---------------- */
    const fetchCardDetails = async (id) => {
        const accessToken = await refresh_token();
        if (!accessToken) return;

        try {
            const res = await axios.get(
                `${BASEURL}/api/crm/cards/${id}/`,
                { headers: { Authorization: `Bearer ${accessToken}` } }
            );
            setSelectedCard(res.data);
        } catch (error) {
            console.error("Error fetching card:", error);
        }
    };

    const exportCardsExcel = () => {
        if (!filteredCards.length) {
            alert("No data to export");
            return;
        }

        const data = filteredCards.map(card => ({
            ID: card.id,
            Model: card.model || "",
            Customer: card.customer_name || "",
            Phone: card.customer_phone || "",
            Region: card.region || "",
            Address: card.address || "",
            "Installation Date": formatDate(card.date_of_installation),
            "Warranty Start": formatDate(card.warranty_start_date),
            "Warranty End": formatDate(card.warranty_end_date),
            "AMC Start": formatDate(card.amc_start_date),
            "AMC End": formatDate(card.amc_end_date),
        }));

        const worksheet = XLSX.utils.json_to_sheet(data);
        const workbook = XLSX.utils.book_new();

        XLSX.utils.book_append_sheet(workbook, worksheet, "Cards");

        const buffer = XLSX.write(workbook, {
            bookType: "xlsx",
            type: "array",
        });

        const blob = new Blob([buffer], {
            type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        });

        saveAs(blob, "Service_Cards.xlsx");
    };


    /* ---------------- UPDATE CARD ---------------- */
    const updateCard = async () => {
        if (!selectedCard) return;

        const confirmUpdate = window.confirm("Are you sure you want to update this card?");
        if (!confirmUpdate) return;

        const accessToken = await refresh_token();
        if (!accessToken) return;

        const payload = {
            model: selectedCard.model,
            customer_name: selectedCard.customer_name,
            region: selectedCard.region,
            address: selectedCard.address,
            date_of_installation: selectedCard.date_of_installation,
            warranty_start_date: selectedCard.warranty_start_date,
            warranty_end_date: selectedCard.warranty_end_date,
            ...(selectedCard.amc_start_date && {
                amc_start_date: selectedCard.amc_start_date,
                amc_end_date: selectedCard.amc_end_date,
            }),
        };

        try {
            await axios.patch(
                `${BASEURL}/api/crm/cards/${selectedCard.id}/`,
                payload,
                { headers: { Authorization: `Bearer ${accessToken}` } }
            );

            alert("Card updated successfully");
            window.location.reload();
        } catch (error) {
            console.error("Update failed:", error);
            alert("Failed to update card");
        }
    };

    /* ---------------- FILTER + SORT ---------------- */
    const filteredCards = [...cardList]
        .filter(card => {
            if (!search) return true;
            if (searchBy === "phone") {
                return card.customer_phone?.includes(search);
            }
            return card.customer_name?.toLowerCase().includes(search.toLowerCase());
        })
        .sort((a, b) => {
            switch (sortBy) {
                case "oldest":
                    return a.id - b.id;
                case "name":
                    return a.customer_name.localeCompare(b.customer_name);
                case "install":
                    return new Date(b.date_of_installation) - new Date(a.date_of_installation);
                default: // latest
                    return b.id - a.id;
            }
        });

    /* ---------------- DATE FORMAT ---------------- */
    const formatDate = (date) => {
        if (!date) return "";
        const d = new Date(date);
        if (isNaN(d)) return "";
        return `${String(d.getDate()).padStart(2, "0")}/${String(d.getMonth() + 1).padStart(2, "0")}/${d.getFullYear()}`;
    };

    return (
        <div className="showcard-cont">
            {/* LEFT */}
            <div className='showcard-left'>
                <div className='showcard-top'>
                    <div className='showcard-count-cont'>
                        <div className='showcard-count-box'>
                            <p className="showcard-count-value">{filteredCards.length}</p>
                            <p className="showcard-count-title">Total Cards</p>
                        </div>
                        <FaAddressCard size={40} color='green' />
                    </div>

                    <div className='showcard-edit-cont'>
                        <select
                            className='showcard-edit-select'
                            value={searchBy}
                            onChange={(e) => setSearchBy(e.target.value)}
                        >
                            <option value="name">Customer Name</option>
                            <option value="phone">Customer Phone</option>
                        </select>

                        <input
                            placeholder={`Search by ${searchBy}`}
                            value={search}
                            onChange={(e) => setSearch(e.target.value)}
                            className='showcard-edit-input'
                        />

                        <select
                            className='showcard-edit-select'
                            value={sortBy}
                            onChange={(e) => setSortBy(e.target.value)}
                        >
                            <option value="latest">Latest First</option>
                            <option value="oldest">Oldest First</option>
                            <option value="name">Customer Name (A-Z)</option>
                            <option value="install">Installation Date</option>
                        </select>
                        <button
                            className="showcard-details-but"
                            onClick={exportCardsExcel}
                        >
                            Export
                        </button>
                    </div>
                </div>
                <div className='showcard-bottom'>

                    <div className="showcard-list-cont">
                        <table className="showcard-list">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Model</th>
                                    <th>Customer</th>
                                    <th>Installation Date</th>
                                </tr>
                            </thead>
                            <tbody>
                                {filteredCards.map(card => (
                                    <tr
                                        key={card.id}
                                        onClick={() => fetchCardDetails(card.id)}
                                        style={{ cursor: "pointer" }}
                                    >
                                        <td>{card.id}</td>
                                        <td>{card.model}</td>
                                        <td>{card.customer_name}</td>
                                        <td>{formatDate(card.date_of_installation)}</td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>

                    {/* RIGHT */}
                    <div className='showcard-right'>
                        <div className='showcard-details-cont'>
                            <p className="showcard-details-title">Card Details</p>

                            <div className="showcard-details-box-cont">
                                {selectedCard ? (
                                    <>
                                        <DetailBox type="text" label="Model" field="model" data={selectedCard} setData={setSelectedCard} />
                                        <DetailBox type="text" label="Customer Name" field="customer_name" data={selectedCard} setData={setSelectedCard} />
                                        <DetailBox type="text" label="Region" field="region" data={selectedCard} setData={setSelectedCard} />
                                        <DetailBox type="text" label="Address" field="address" data={selectedCard} setData={setSelectedCard} />
                                        <DetailBox type="date" label="Date Of Installation" field="date_of_installation" data={selectedCard} setData={setSelectedCard} />
                                        <DetailBox type="date" label="Warranty Start Date" field="warranty_start_date" data={selectedCard} setData={setSelectedCard} />
                                        <DetailBox type="date" label="Warranty End Date" field="warranty_end_date" data={selectedCard} setData={setSelectedCard} />
                                        <DetailBox type="date" label="AMC Start Date" field="amc_start_date" data={selectedCard} setData={setSelectedCard} />
                                        <DetailBox type="date" label="AMC End Date" field="amc_end_date" data={selectedCard} setData={setSelectedCard} />
                                    </>
                                ) : <p>No Card Selected</p>}
                            </div>

                            <div style={{ display: "flex", gap: "10px" }}>
                                <button
                                    className='showcard-details-but'
                                    onClick={updateCard}
                                >
                                    Update
                                </button>

                                <button
                                    className='showcard-details-but'
                                    style={{
                                        backgroundColor: "#d9534f",
                                        color: "#fff"
                                    }}
                                    onClick={deleteCard}
                                >
                                    Delete
                                </button>
                            </div>

                        </div>
                    </div>
                </div>
                
            </div>
        </div>
    );
};

/* ---------------- DETAIL BOX ---------------- */
const DetailBox = ({ type, label, field, data, setData }) => (
    <div className="showcard-details-box">
        <p className="showcard-details-key">{label}</p>
        <input
            className="showcard-details-value"
            type={type}
            value={data[field] || ""}
            onChange={(e) => setData(prev => ({ ...prev, [field]: e.target.value }))}
        />
    </div>
);

export default ShowCard;
