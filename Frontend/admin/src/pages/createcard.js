import '../styles/createcard.css';
import CreateCardimg from '../assets/createcard.jpg';
import axios from 'axios';
import Cookies from 'js-cookie';
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';

const BASEURL = "http://127.0.0.1:8000";

const CreateCard = () => {

    const navigate = useNavigate();

    /* ---------------- AUTH CHECK ---------------- */
    useEffect(() => {
        const isLoggedIn = Cookies.get('Login') === 'True';
        if (!isLoggedIn) navigate('/head/');
    }, [navigate]);

    /* ---------------- STATE ---------------- */
    const [customer, setCustomer] = useState(null);

    const [model, setModel] = useState("");
    const [cardType, setCardType] = useState("normal");

    const [address, setAddress] = useState("");
    const [city, setCity] = useState("");

    const [doi, setDoi] = useState("");
    const [wsd, setWsd] = useState("");
    const [wed, setWed] = useState("");

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

    /* ---------------- GET CUSTOMER BY PHONE ---------------- */
    const getUserByPhone = async (phone) => {
        if (phone.length !== 10) {
            setCustomer(null);
            return;
        }

        const accessToken = await refresh_token();
        if (!accessToken) return;

        try {
            const res = await axios.get(
                `${BASEURL}/api/auth/admin/users/?phone=${phone}&role=customer`,
                { headers: { Authorization: `Bearer ${accessToken}` } }
            );

            if (res.data.length > 0) {
                const user = res.data[0];
                console.log(user)
                setCustomer(user);
                setAddress(user.address || "");
                setCity(user.city || "");
            } else {
                setCustomer(null);
            }
        } catch (error) {
            console.error("Customer fetch error:", error);
            setCustomer(null);
        }
    };

    /* ---------------- WARRANTY AUTO CALC ---------------- */
    const handleWarrantyStart = (date) => {
        setWsd(date);

        if (date) {
            const start = new Date(date);
            const end = new Date(start-1);
            end.setFullYear(end.getFullYear() + 1);
            setWed(end.toISOString().split("T")[0]);
        }
    };

    /* ---------------- CARD TYPE CHANGE ---------------- */
    const handleCardTypeChange = (type) => {
        setCardType(type);

        if (type === "om") {
            const today = new Date().toISOString().split("T")[0];
            setDoi(today);
            setWsd(today);
            setWed(today);
        } else {
            setDoi("");
            setWsd("");
            setWed("");
        }
    };

    /* ---------------- CREATE CARD ---------------- */
    const create_card = async () => {
        if (!model || !customer || !address || !city) {
            alert("Please fill all required fields");
            return;
        }

        const confirmCreate = window.confirm(
            `Are you sure you want to create this card?\n\n` +
            `Customer: ${customer.name}\n` +
            `Model: ${model}\n` +
            `Card Type: ${cardType.toUpperCase()}`
        );

        if (!confirmCreate) return;

        const accessToken = await refresh_token();
        if (!accessToken) return;

        const payload = {
            model,
            customer: customer.id,
            customer_name: customer.name,
            card_type: cardType,
            region: customer.region || "rajapalayam",
            address,
            city,
            postal_code: "626117",
            date_of_installation: doi,
            warranty_start_date: wsd,
            warranty_end_date: wed,
        };

        try {
            await axios.post(
                BASEURL + "/api/crm/cards/",
                payload,
                { headers: { Authorization: `Bearer ${accessToken}` } }
            );

            alert("Card created successfully");
            window.location.reload();
        } catch (error) {
            console.error("Create card error:", error);
            alert("Failed to create card");
        }
    };


    /* ---------------- UI ---------------- */
    return (
        <div className="createcard-cont">
            <div className='createcard-l'>
                <div className='createcard-card'>
                    <p className='createcard-title'>Create Card</p>

                    <div className='createcard-inputs'>

                        <div className='createcard-input-cont'>
                            <p>Model Name *</p>
                            <input className="createcard-card-input" placeholder="Model Name" onChange={(e) => setModel(e.target.value)} />
                        </div>

                        <div className='createcard-input-cont'>
                            <p>
                                Customer :
                                {customer ? ` ${customer.name} (ID: ${customer.id})` : " Not Found"}
                            </p>
                            <input
                                className="createcard-card-input"
                                placeholder="Customer Phone"
                                onChange={(e) => getUserByPhone(e.target.value)}
                            />
                        </div>

                        <div className='createcard-input-cont'>
                            <p>Card Type *</p>
                            <select
                                className="createcard-card-input"
                                value={cardType}
                                onChange={(e) => handleCardTypeChange(e.target.value)}
                            >
                                <option value="normal">Normal</option>
                                <option value="om">OM (Other Machine)</option>
                            </select>
                        </div>

                        <div className='createcard-input-cont'>
                            <p>Address *</p>
                            <input
                                className="createcard-card-input"
                                value={address}
                                onChange={(e) => setAddress(e.target.value)}
                                placeholder='Address'
                            />
                        </div>

                        <div className='createcard-input-cont'>
                            <p>City *</p>
                            <input
                                className="createcard-card-input"
                                value={city}
                                onChange={(e) => setCity(e.target.value)}
                                placeholder='City'
                            />
                        </div>

                        {cardType === "normal" && (
                            <>
                                <div className='createcard-input-cont'>
                                    <p>Date Of Installation *</p>
                                    <input type="date" className="createcard-card-input" onChange={(e) => setDoi(e.target.value)} />
                                </div>

                                <div className='createcard-input-cont'>
                                    <p>Warranty Start Date *</p>
                                    <input type="date" className="createcard-card-input" onChange={(e) => handleWarrantyStart(e.target.value)} />
                                </div>

                                <div className='createcard-input-cont'>
                                    <p>Warranty End Date *</p>
                                    <input type="date" className="createcard-card-input" value={wed} onChange={(e) => setWed(e.target.value)} />
                                </div>
                            </>
                        )}

                    </div>

                    <button className='createcard-card-button' onClick={create_card}>
                        Create Card
                    </button>
                </div>
            </div>

            <div className='createcard-r'>
                <div className='createcard-img-cont'>
                    <img src={CreateCardimg} alt='illustration' />
                    <p>Create a service card with flexible card types and warranty handling.</p>
                </div>
            </div>
        </div>
    );
};

export default CreateCard;
