
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import '../styles/editreq.css';
import axios from 'axios';
import Cookies from 'js-cookie';

const EditReq = () => {

    /* ------------------------------------------------------------------ */
        /* ───────────────────────────  ROUTING  ──────────────────────────── */
        /* ------------------------------------------------------------------ */
        const navigate = useNavigate();
    
        /** Redirect unauthenticated users to /head/ immediately. */
        useEffect(() => {
            const isLoggedIn = Cookies.get('Login') === 'True';
            if (!isLoggedIn) navigate('/head/');
        }, [navigate]);
    
        
    const [reqData, setreqData] = useState(null);
    const [AllreqData, setAllreqData] = useState([]);
    const refreshToken = Cookies.get('refresh_token');

    const refresh_token = async () => {
        try {
            const res = await axios.post("http://157.173.220.208/log/token/refresh/", 
                { 'refresh': refreshToken }, 
                { headers: { "Content-Type": "application/json" } }
            );
            Cookies.set('refresh_token', res.data.refresh, { expires: 7 });
            return res.data.access;
        } catch (error) {
            console.error("Error refreshing token:", error);
            return null;
        }
    };

    const fetch_req = async (accessToken) => {
        try {
            const response = await axios.get("http://157.173.220.208/utils/headvieweditreq/", {
                headers: { Authorization: `Bearer ${accessToken}` }
            });
            if (response.data) {
                setAllreqData(response.data);
            }
        } catch (error) {
            console.error("Error fetching data:", error);
            setAllreqData([]);
        }
    };

    const fetch_req_in = async () => {
        const RT = await refresh_token();
        if (RT) await fetch_req(RT);
    };

    useEffect(() => {
        fetch_req_in();
    }, []);

    const accept_req = async (req_id) => {
        const confirmAction = window.confirm("Are you sure you want to APPROVE this request?");
        if (!confirmAction) return;

        const AT = await refresh_token();
        try {
            const response = await axios.get(`http://157.173.220.208/utils/headeditreq/${req_id}`, {
                headers: { Authorization: `Bearer ${AT}` }
            });
            if (response.data) {
                console.log(response.data);
                setreqData(null);
                window.location.reload();
            }
        } catch (error) {
            console.error("Error approving request:", error);
        }
    };

    const reject_req = async (req_id) => {
        const confirmAction = window.confirm("Are you sure you want to REJECT this request?");
        if (!confirmAction) return;

        const AT = await refresh_token();
        try {
            const response = await axios.get(`http://157.173.220.208/utils/headrejecteditreq/${req_id}`, {
                headers: { Authorization: `Bearer ${AT}` }
            });
            if (response.data) {
                console.log(response.data);
                setreqData(null);
                window.location.reload();
            }
        } catch (error) {
            console.error("Error approving request:", error);
        }
    };

    return (
        <div className="editreq-cont">
            <div className="editreq-l">
                <div className="editreq-table">
                    <table className="editreq-list">
                        <thead>
                            <tr>
                                <th>ID</th>
                                <th>Staff ID</th>
                                <th>Staff Name</th>
                                <th>Customer ID</th>
                                <th>Check</th>
                            </tr>
                        </thead>
                        <tbody>
                            {AllreqData.length > 0 ? (
                                AllreqData.map((edreq) => (
                                    <tr key={edreq.id}>
                                        <td>{edreq.id}</td>
                                        <td>{edreq.staff}</td>
                                        <td>{edreq.staff_name}</td>
                                        <td>{edreq.customer}</td>
                                        <td>
                                            <button className='editreq-table-checkbut' onClick={() => setreqData(edreq)}>Check</button>
                                        </td>
                                    </tr>
                                ))
                            ) : (
                                <tr>
                                    <td colSpan="5">No requests available</td>
                                </tr>
                            )}
                        </tbody>
                    </table>
                </div>
            </div>
            <div className="editreq-r">
                <div className="editreq-r-cont">
                    <p className="editreq-details-title">Edit Request Details</p>
                    <div className="editreq-details-box-cont">
                        {reqData ? (
                            <>
                                <DetailBox label="Staff ID" value={reqData.staff} />
                                <DetailBox label="Staff Name" value={reqData.staff_name} />
                                <DetailBox label="Customer ID" value={reqData.customer} />
                                <div className='editreq-divider'><p></p></div>
                                {reqData.customerData ? (
                                    <>
                                        <DetailBox label="Name" value={reqData.customerData.name} />
                                        <DetailBox label="Phone" value={reqData.customerData.phone} />
                                        <DetailBox label="Email" value={reqData.customerData.email} />
                                        <DetailBox label="Region" value={reqData.customerData.region} />
                                        <DetailBox label="Address" value={reqData.customerData.address} />
                                        <DetailBox label="City" value={reqData.customerData.city} />
                                        <DetailBox label="District" value={reqData.customerData.district} />
                                        <DetailBox label="Postal Code" value={reqData.customerData.postal_code} />
                                    </>
                                ) : <p>Customer data not available</p>}
                            </>
                        ) : <p>No Request Selected</p>}
                    </div>
                    <div>
                        <button 
                            className='editreq-details-but' 
                            onClick={() => reqData && accept_req(reqData.id)}
                        >
                            Approve
                        </button>
                        <button className='editreq-details-but-r' onClick={() => reqData && reject_req(reqData.id)}>Reject</button>
                    </div>
                </div>
            </div>
        </div>
    );
};

const DetailBox = ({ label, value }) => (
    <div className="editreq-details-box">
        <p className="editreq-details-key">{label}</p>
        <p className="editreq-details-value">{value || ""}</p>
    </div>
);

export default EditReq;
