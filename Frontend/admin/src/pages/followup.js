import '../styles/followup.css';
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import Cookies from 'js-cookie';

const FollowUp = () => {

    const BASEURL = "http://157.173.220.208";
    const navigate = useNavigate();

    const [days, setDays] = useState(30);
    const [data, setData] = useState([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    const token = Cookies.get("access");

    const fetchFollowUps = async () => {
        setLoading(true);
        setError(null);

        try {
            const res = await axios.get(
                `${BASEURL}/api/crm/reports/follow-up/?days=${days}`,
                {
                    headers: {
                        Authorization: `Bearer ${token}`
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
            {data.length > 0 && (
                <table className='followup-table'>
                    <thead>
                        <tr>
                            <th>Customer</th>
                            <th>Phone</th>
                            <th>Model</th>
                            <th>City</th>
                            <th>Last Service</th>
                            <th>Pending Days</th>
                            <th>Action</th>
                        </tr>
                    </thead>

                    <tbody>
                        {data.map(card => (
                            <tr key={card.id}>
                                <td>{card.customer_name}</td>
                                <td>{card.customer_phone}</td>
                                <td>{card.model}</td>
                                <td>{card.city}</td>
                                <td>{card.last_service_date}</td>

                                <td className='danger'>
                                    {card.days_since_service} days
                                </td>

                                <td>
                                    <button
                                        className='create-btn'
                                        onClick={() =>
                                            navigate(`/admin/create-service/${card.id}`)
                                        }
                                    >
                                        Create Service
                                    </button>
                                </td>
                            </tr>
                        ))}
                    </tbody>
                </table>
            )}

        </div>
    );
};

export default FollowUp;
