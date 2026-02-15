import '../styles/followup.css';
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import Cookies from 'js-cookie';

const FollowUp = () => {

    const BASEURL = "http://157.173.220.208";
    const navigate = useNavigate();

    const [days, setDays] = useState(60);
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

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

    const fetchFollowUps = async () => {
        setLoading(true);
        setError(null);

        const AT = await refresh_token();
        if (!AT) return;

        try {
            const res = await axios.get(
                `${BASEURL}/api/crm/reports/follow-up/?days=${days}`,
                {
                    headers: {
                        Authorization: `Bearer ${AT}`
                    }
                }
            );

            setData(res.data);
        } catch (err) {
            console.error(err);
            setError("Failed to load follow-up data");
        } finally {
            setLoading(false);
        }
    };

    useEffect(() => {
        fetchFollowUps();
    }, []);

    const handleSearch = () => {
        fetchFollowUps();
    };

    return (
        <div className='followup-main'>

            <h2>Customer Follow-Up</h2>

            {/* Filter */}
            <div className='followup-filter'>
                <label>Service older than</label>

                <input
                    type="number"
                    value={days}
                    onChange={(e) => setDays(e.target.value)}
                />

                <span>days</span>

                <button onClick={handleSearch}>Search</button>
            </div>

            {/* Loading */}
            {loading && <p className='info'>Loading...</p>}

            {/* Error */}
            {error && <p className='error'>{error}</p>}

            {/* Empty */}
            {!loading && data.length === 0 && (
                <p className='info'>No follow-ups required 🎉</p>
            )}

            {/* Table */}
            <div className='followup-table-cont'>
                {data.length > 0 && (
                    <table className='followup-table'>
                        <thead>
                            <tr>
                                <th>S.No</th>
                                <th>Customer</th>
                                <th>Name</th>
                                <th>Phone</th>
                                <th>Card ID</th>
                                <th>Model</th>
                                <th>City</th>
                                <th>Last Service</th>
                                <th>Pending Days</th>
                            </tr>
                        </thead>

                        <tbody>
                            {data.map((card,index) => (
                                <tr key={card.id}>
                                    <td>{index+1}</td>
                                    <td>{card.customer_code}</td>
                                    <td>{card.customer_name}</td>
                                    <td>{card.customer_phone}</td>
                                    <td>{card.id}</td>
                                    <td>{card.model}</td>
                                    <td>{card.city}</td>
                                    <td>{card.last_service_date}</td>

                                    <td className='danger'>
                                        {card.days_since_service} days
                                    </td>
                                </tr>
                            ))}
                        </tbody>
                    </table>
                )}
            </div>

        </div>
    );
};

export default FollowUp;
