import '../styles/service.css';
import { MdVerified } from "react-icons/md";
import { MdUpcoming } from "react-icons/md";
import { TiWarning } from "react-icons/ti";
import { PiStackSimpleFill } from "react-icons/pi";
import { MdAddToPhotos } from "react-icons/md";
import { RiEdit2Fill } from "react-icons/ri";
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import Cookies from 'js-cookie';
import { useParams } from "react-router-dom";

const Service = () => {

    const BASEURL="http://127.0.0.1:8000";
    const navigate = useNavigate();

    const [serviceList, setServiceList]=useState([]);
    const [boxData, setBoxData] = useState({ "pending": 0, "assigned": 0,"completed": 0, "total": 0 });
    const [showAssignStaffForm, setShowAssignStaffForm] = useState(false);

    const [filteredList, setFilteredList] = useState([]);
    const [searchType, setSearchType] = useState("id");
    const [searchQuery, setSearchQuery] = useState("");

    const [editService, setEditService]=useState(true);
    const [fetchServiceId, setFetchServiceId]=useState();

    const [assignServiceStaff, setAssignServiceStaff]=useState(0);
    const [assignServiceDate, setAssignServiceDate]=useState("");
    const [assignServiceStaffPhone, setAssignServiceStaffPhone]=useState("");

    const [staffAttendanceStatus, setStaffAttendanceStatus] = useState(null); 
    const [createStaffAttendanceStatus, setCreateStaffAttendanceStatus] = useState(null);

    const [sortBy, setSortBy] = useState("latest");


    // ~~~~~~~~~~ CREATE SERVICE DATA ~~~~~~~~~~~~~

    const [createServiceCardID, setcreateServiceCardID]=useState(0);
    const [createServiceCardAll, setcreateServiceCardAll]=useState([]);
    const [createServiceDescription, setCreateServiceDescription]=useState("");
    const [createServiceType, setCreateServiceType]=useState("normal");
    const [createServiceDate, setCreateServiceDate]=useState("");
    const [createServiceVisitType, setCreateServiceVisitType]=useState("C");
    const [createServiceStaff, setCreateServiceStaff]=useState(0);
    const [createServiceStaffPhone, setCreateServiceStaffPhone]=useState("");
    const [createServiceCustomer, setCreateServiceCustomer]=useState(0);
    const [createServiceCustomerPhone, setCreateServiceCustomerPhone]=useState("");

    // ~~~~~~~~~~~ SERVICE FORM DATA ~~~~~~~~~~~~~~

    const [serviceFetch,setServiceFetch]=useState(false);

    const [serviceData, setServiceData]=useState({});

    const [serviceID, setServiceID]=useState(0);
    const [serviceCardID, setServiceCardID]=useState(0);
    const [serviceCustomerID, setServiceCustomerID]=useState(0);
    const [serviceStaffID, setServiceStaffID]=useState(0);

    const [serviceType, setServiceType]=useState("normal");
    const [serviceStatus, setServiceStatus]=useState("booked");
    const [serviceDescription, setServiceDescription]=useState("");

    const [serviceBookedDate, setServiceBookedDate]=useState("");
    const [servicePreferedDate, setServicePreferedDate]=useState("");
    const [serviceScheduleDate, setServiceScheduleDate]=useState("");
    const [serviceNextServiceDate, setServiceNextServiceDate]=useState("I");

    const [serviceVisitType, setServiceVisitType]=useState("I");

    const [serviceEntries, setServiceEntries]=useState([]);

    const [serviceHasFeedback, setServiceHasFeedback]=useState(false);
    const [serviceFeedback, setServiceFeedback]=useState("");
    const [serviceRating, setServiceRating]=useState(0);

    const [serviceOtpPhone, setServiceOtpPhone]=useState(null);

    const [serviceAddress, setServiceAddress]=useState("");

    // ~~~~~~~~~~~~~~~~ CREATE SERVICE DATA ~~~~~~~~~~~~~~~~~~

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

    // ~~~~~~~~~~~ GET SERVICE BY ID ~~~~~~~~~~~~~~

    const getServiceByID=async(id)=>{
        const Token=await refresh_token();
        if(!Token){
            navigate('/head/');
            return null;
        }
        try {
            const res = await axios.get(BASEURL+`/api/crm/services/${id}/`, { headers: { Authorization: `Bearer ${Token}` } });
            console.log("GET SERVICE BY ID");
            return res.data;
        } catch (error) {
            console.error("Error in Get Service By ID:", error);
            return null;
        }
    }

    // ~~~~~~~~~~~ PATCH SERVICE BY ID ~~~~~~~~~~~~~~

    const patchServiceByID=async(id, updatedData)=>{
        const Token=await refresh_token();
        if(!Token){
            navigate('/head/');
            return null;
        }
        try {
            const reqData=updatedData
            const res = await axios.patch(BASEURL+`/api/crm/services/${id}/`, reqData, { headers: { Authorization: `Bearer ${Token}` } });
            console.log("PATCH SERVICE BY ID");
            console.log(res);
            await updateServiceFormWithID(id);
            await updateServiceList();
            alert("Service updated successfully!");
        } catch (error) {
            console.error("Error in Patch Service By ID:", error);
            alert("Error In Updating Service!");
            return null;
        }
    }

    // ~~~~~~~~~~~ POST SERVICE BY ID ~~~~~~~~~~~~~~

    const postServiceByID=async(serviceData)=>{
        const Token=await refresh_token();
        if(!Token){
            navigate('/head/');
            return null;
        }
        try {
            const reqData=serviceData
            const res = await axios.post(BASEURL+`/api/crm/services/admin_create/`, reqData, { headers: { Authorization: `Bearer ${Token}` } });
            console.log("POST SERVICE BY ID");
            await updateServiceList();
            alert("Service Created successfully!");
        } catch (error) {
            console.error("Error in Patch Service By ID:", error);
            alert("Error In Creating Service!");
            return null;
        }
    }

    // ~~~~~~~~~~~ POST ASSIGN STAFF TO SERVICE ~~~~~~~~~~~~~~

    const postAssignStaff=async(service_id, staff_id, scheduled_date)=>{
        const Token=await refresh_token();
        if (!Token){
            navigate('/head/');
            return null;
        }
        try {
            const reqData={
                assigned_to: staff_id,
                scheduled_at: scheduled_date
            }
            const res = await axios.post(BASEURL+`/api/crm/services/${service_id}/assign/`, reqData, { headers: { Authorization: `Bearer ${Token}` } });
            console.log("POST ASSIGN STAFF TO SERVICE");
            await updateServiceList();
            setShowAssignStaffForm(false);
            alert("Staff Assigned To Service successfully!");
        } catch (error) {
            console.error("Error in Assign Staff To Service:", error);
            alert("Error In Assign Staff To Service!");
            return null;
        }
    }

    // ~~~~~~~~~~~ GET SERVICE LIST ~~~~~~~~~~~~~~

    const getServiceList=async()=>{
        const Token=await refresh_token();
        if(!Token){
            navigate('/head/');
            return null;
        }
        try {
            const res = await axios.get(BASEURL+`/api/crm/services/`, { headers: { Authorization: `Bearer ${Token}` } });
            console.log("GET SERVICE LIST");
            return res.data;
        } catch (error) {
            console.error("Error in Get Service List:", error);
            return null;
        }
    }

    // ~~~~~~~~~~~ GET USER BY PHONE ~~~~~~~~~~~~~

    const getUserByPhone=async(phone)=>{
        const Token=await refresh_token();
        if(!Token){
            navigate('/head/');
            return null;
        }
        try {
            const res = await axios.get(BASEURL+`/api/auth/admin/users/?phone=${phone}`, { headers: { Authorization: `Bearer ${Token}` } });
            console.log("GET USER BY PHONE");
            return res.data[0];
        } catch (error) {
            console.error("Error in Get User By Phone:", error);
            return null;
        }
    }

    // ~~~~~~~~~~~ GET CARD BY USER ~~~~~~~~~~~~~

    const getCardByUser=async(id)=>{
        const Token=await refresh_token();
        if(!Token){
            navigate('/head/');
            return null;
        }
        try {
            const res = await axios.get(BASEURL+`/api/crm/cards/?customer=${id}`, { headers: { Authorization: `Bearer ${Token}` } });
            console.log("GET CARD BY USER");
            return res.data;
        } catch (error) {
            console.error("Error in Get card By User:", error);
            return null;
        }   
    }


    // ~~~~~~~~ ATTENDANCE API FUNCTION ~~~~~~~~~~

    const getAttendanceByDate = async (date) => {
        const Token = await refresh_token();
        if (!Token) {
            navigate('/head/');
            return null;
        }

        try {
            const res = await axios.get(
                `${BASEURL}/api/crm/attendance/by_date/?date=${date}`,
                { headers: { Authorization: `Bearer ${Token}` } }
            );
            return res.data.records;
        } catch (error) {
            console.error("Error fetching attendance:", error);
            return null;
        }
    };




    // ===================== UI UPDATE FUNCTIONS ===========================

    // ~~~~~~~~~~~~ UPDATE SERVICE FORM DATA WITH SERVICE ID ~~~~~~~~~~~~~~~

    const updateServiceFormWithID=async(id)=>{
        setServiceID(0);
        setServiceCardID(0);
        setServiceCustomerID(0);
        setServiceType("normal");
        setServiceStatus("pending");
        setServiceDescription("");
        setServicePreferedDate("");
        setServiceScheduleDate("");
        setServiceStaffID("");
        setServiceVisitType("");
        setServiceNextServiceDate("");
        setServiceEntries([]);
        setServiceHasFeedback(false);
        setServiceFeedback("");
        setServiceRating("");
        setServiceBookedDate("");
        setServiceOtpPhone("");
        setServiceFetch(true);
        setServiceData({});
        setServiceAddress("");
        const data=await getServiceByID(id);
        console.log(data);
        if(data!=null){
            setServiceID(data.id);
            setServiceCardID(data.card);
            setServiceCustomerID(data.requested_by);
            setServiceType(data.service_type);
            setServiceStatus(data.status);
            setServiceDescription(data.description);
            setServicePreferedDate(data.preferred_date);
            setServiceScheduleDate(data.scheduled_at);
            setServiceStaffID(data.assigned_to);
            setServiceVisitType(data.visit_type);
            setServiceNextServiceDate(data.next_service_date);
            setServiceEntries(data.entries);
            setServiceHasFeedback(data.feedback!=null);
            setServiceFeedback(data.feedback==null?"":data.feedback["comments"]);
            setServiceRating(data.feedback==null?"":data.feedback["rating"]);
            setServiceBookedDate(data.created_at);
            setServiceOtpPhone(data.otp_phone);
            setServiceFetch(true);
            setServiceData(data);
            setServiceAddress(data.card_data.address+", "+data.card_data.city);
            if (data.assigned_to && isToday(data.scheduled_at)) {
                const records = await getAttendanceByDate(data.scheduled_at);

                if (records) {
                    const staffRecord = records.find(
                        r => r.user_id === data.assigned_to
                    );

                    if (staffRecord) {
                        setStaffAttendanceStatus(staffRecord.status); // present / absent
                    } else {
                        setStaffAttendanceStatus(null);
                    }
                }
            } else {
                setStaffAttendanceStatus(null);
            }
        }
    }

    // ~~~~~~~~~~ UPDATE THE SERVICE TABLE ~~~~~~~~~~~

    const updateServiceList=async()=>{

        const data=await getServiceList();
        console.log(data);
        if(data.length!=0){
            setServiceList(data);
            const sPen = data.filter(service => service.status === "pending").length;
            const sCom = data.filter(service => service.status === "completed").length;
            const sAss = data.filter(service => service.status === "assigned").length;
            const sTot = data.length;
            setBoxData({ "pending": sPen, "assigned": sAss,"completed": sCom, "total": sTot});
        }
    }

    // ~~~~~~~~~~~ UPDATE SERVICE TABLE BY FILTER ~~~~~~~~~~~~~~

    const getAssignedServiceList = () => setFilteredList(serviceList.filter(service => service.status === "assigned"));
    const getPendingServiceList = () => setFilteredList(serviceList.filter(service => service.status === "pending"));
    const getCompletedServiceList = () => setFilteredList(serviceList.filter(service => service.status === "completed"));
    const getAllServiceList = async() => {await updateServiceList();setFilteredList(serviceList);};


    // ~~~~~~~~~~ EDIT SERVICE FORM ~~~~~~~~~~`

    const editServiceForm=async()=>{
        const data={
            "assigned_to":serviceStaffID,
            "card":serviceCardID,
            "scheduled_at":serviceScheduleDate,
            "next_service_date":serviceNextServiceDate,
            "description":serviceDescription,
            "service_type":serviceType,
            "visit_type":serviceVisitType,
            "status":serviceStatus
        }
        if (serviceFetch) {
            const confirmEdit = window.confirm("Are you sure you want to edit this service?");
            if (confirmEdit) {
                await patchServiceByID(serviceID,data);
            } else {
                alert("Service Edit Cancelled");
            }
        } else {
            alert("Please Fetch the Service ID First");
        }
    }

    // ~~~~~~~~~~ ASSIGN STAFF TO SERVICE ~~~~~~~~

    const handleAssignStaffForm=async()=>{
        if(assignServiceStaff!=null && assignServiceDate !=""){
            const confirmEdit = window.confirm("Are you sure you want to Assign Staff this service?");
            if (confirmEdit) {
                await postAssignStaff(serviceID, assignServiceStaff["id"], assignServiceDate);
            } else {
                alert("Service Edit Cancelled");
            }
        }

    }

    // ~~~~~~~~~~ BOOK SERVICE FORM ~~~~~~~~~~`

    const bookService=async()=>{
        const data={
            "card": createServiceCardID,
            "description": createServiceDescription,
            "service_type": createServiceType,
            "preferred_date": createServiceDate,
            "visit_type": createServiceVisitType,
            "requested_by":createServiceCustomer["id"],
            "assigned_to":createServiceStaff["id"]
        }
        const confirmEdit = window.confirm("Are you sure you want to Create service?");
        if (confirmEdit) {
            await postServiceByID(data);
        } else {
            alert("Service Book Cancelled");
        }
    }

    // ~~~~~~~~~~~ ASSIGN PHONE TO CUSTOMER ~~~~~~~~~~~~~~~

    const assignPhoneToCustomer=async(phone)=>{
        if(phone.length>=10){
            const user=await getUserByPhone(phone);
            if(user!=null && user["role"]=="customer"){
                setCreateServiceCustomer(user);
                const cards=await getCardByUser(user.id);
                setcreateServiceCardAll(cards);
            }
        }
        else{
            setCreateServiceCustomer(null);
            setcreateServiceCardAll([])
        }
    }

    // ~~~~~~~~~~~ ASSIGN PHONE TO STAFF ~~~~~~~~~~~~~~~

    const assignPhoneToStaff=async(phone)=>{
        if(phone.length>=10){
            const user=await getUserByPhone(phone);
            if(user!=null && (user["role"]=="worker" || user["role"]=="staff")){
                setCreateServiceStaff(user);
            }
        }else{
            setCreateServiceStaff(null);
        }
    }

    // ~~~~~~~~~~~ ASSIGN SERVICE PHONE TO STAFF ~~~~~~~~~~~~~~~

    const assignServicePhoneToStaff=async(phone)=>{
        if(phone.length>=10){
            const user=await getUserByPhone(phone);
            if(user!=null && (user["role"]=="worker" || user["role"]=="staff")){
                setAssignServiceStaff(user);
            }
        }else{
            setAssignServiceStaff(null);
        }
    }

    // ~~~~~~~~~~~~ FORMATE DATE ~~~~~~~~~~~~~

    const formatDate = (date) => {
        if (!date) return "";
        const d = new Date(date);
        if (isNaN(d)) return ""; 
        const day = String(d.getDate()).padStart(2, "0");
        const month = String(d.getMonth() + 1).padStart(2, "0");
        const year = d.getFullYear();
        return `${day}/${month}/${year}`; 
    };

    // ~~~~~~~~~~~~ IS TODAY ~~~~~~~~~~~~~

    const isToday = (dateStr) => {
        if (!dateStr) return false;
        const today = new Date().toISOString().split("T")[0];
        return dateStr === today;
    };

    // ~~~~~~~~~~~~ SORTING ~~~~~~~~~~~~~~~~

    const sortServices = (list, sortType) => {
        const sorted = [...list];

        switch (sortType) {
            case "latest":
                return sorted.sort(
                    (a, b) => new Date(b.created_at) - new Date(a.created_at)
                );

            case "oldest":
                return sorted.sort(
                    (a, b) => new Date(a.created_at) - new Date(b.created_at)
                );

            case "status":
                return sorted.sort((a, b) =>
                    a.status.localeCompare(b.status)
                );

            case "customer":
                return sorted.sort((a, b) =>
                    a.customer_data.name.localeCompare(b.customer_data.name)
                );

            default:
                return sorted;
        }
    };



    // ============= RELOAD DATA =========

    useEffect(() => {
        const isLoggedIn = Cookies.get('Login') === 'True';
        if (!isLoggedIn) navigate('/head/');
    }, [navigate]);

    useEffect(() => {
        updateServiceList();
    }, []);

    useEffect(() => {
        const isLoggedIn = Cookies.get('Login') === 'True';
        if (!isLoggedIn) navigate('/head/');
    }, [navigate]);

    useEffect(() => {
        const query = searchQuery.toLowerCase();
        if (searchType === "id") {
            setFilteredList(serviceList.filter(service => service.id.toString().includes(query)));
        } else if (searchType === "phone") {
            setFilteredList(serviceList.filter(service => service.customer_data.phone?.toLowerCase().includes(query)));
        } else if (searchType === "name") {
            setFilteredList(serviceList.filter(service => service.customer_data.name?.toLowerCase().includes(query)));
        } else {
            setFilteredList(serviceList);
        }
    }, [searchQuery, searchType, serviceList]);

    useEffect(() => {
        const checkAttendance = async () => {
            if (!serviceStaffID || !isToday(serviceScheduleDate)) {
                setStaffAttendanceStatus(null);
                return;
            }

            const records = await getAttendanceByDate(serviceScheduleDate);
            if (!records) {
                setStaffAttendanceStatus(null);
                return;
            }

            const staffRecord = records.find(
                r => r.user_id === Number(serviceStaffID)
            );

            setStaffAttendanceStatus(staffRecord ? staffRecord.status : null);
        };

        checkAttendance();
    }, [serviceStaffID, serviceScheduleDate]);

    useEffect(() => {
        const checkCreateAttendance = async () => {
            if (
                !createServiceStaff ||
                !createServiceStaff.id ||
                !isToday(createServiceDate)
            ) {
                setCreateStaffAttendanceStatus(null);
                return;
            }

            const records = await getAttendanceByDate(createServiceDate);
            if (!records) {
                setCreateStaffAttendanceStatus(null);
                return;
            }

            const staffRecord = records.find(
                r => r.user_id === createServiceStaff.id
            );

            setCreateStaffAttendanceStatus(staffRecord ? staffRecord.status : null);
        };

        checkCreateAttendance();
    }, [createServiceStaff, createServiceDate]);

    useEffect(() => {
        const query = searchQuery.toLowerCase();
        let list = serviceList;

        if (searchType === "id") {
            list = serviceList.filter(service =>
                service.id.toString().includes(query)
            );
        } else if (searchType === "phone") {
            list = serviceList.filter(service =>
                service.customer_data.phone?.toLowerCase().includes(query)
            );
        } else if (searchType === "name") {
            list = serviceList.filter(service =>
                service.customer_data.name?.toLowerCase().includes(query)
            );
        }

        const sortedList = sortServices(list, sortBy);
        setFilteredList(sortedList);

    }, [searchQuery, searchType, serviceList, sortBy]);

    useEffect(() => {
        const checkAssignAttendance = async () => {
            if (
                !assignServiceStaff ||
                !assignServiceStaff.id ||
                !assignServiceDate ||
                !isToday(assignServiceDate)
            ) {
                setStaffAttendanceStatus(null);
                return;
            }

            const records = await getAttendanceByDate(assignServiceDate);
            if (!records) {
                setStaffAttendanceStatus(null);
                return;
            }

            const staffRecord = records.find(
                r => r.user_id === assignServiceStaff.id
            );

            setStaffAttendanceStatus(staffRecord ? staffRecord.status : null);
        };

        checkAssignAttendance();
    }, [assignServiceStaff, assignServiceDate]);






    // +++++++++++++ FRONTEND UI ++++++++++++++++

    return (
        <div className='service-main'>
        {showAssignStaffForm?
        <div className='service-staffassignform'>
            <a className='staffassignform-close' onClick={()=>{setShowAssignStaffForm(false)}}></a>
            <div>
                <p>Assign Staff To The Service {serviceID} for {serviceData.customer_data["name"]}</p>
                <form onSubmit={(e)=>{e.preventDefault(); handleAssignStaffForm();}}>
                    <label>Staff : {assignServiceStaff!=null?assignServiceStaff["name"] + " ( " + assignServiceStaff["id"] + " ) " : "Not Found"}
                        {isToday(assignServiceDate) && staffAttendanceStatus && (
                            <span
                                style={{
                                    marginTop: "6px",
                                    color:
                                        staffAttendanceStatus === "present"
                                            ? "green"
                                            : "red"
                                }}
                            >
                                {staffAttendanceStatus === "present"
                                    ? "Present Today"
                                    : "Absent Today"}
                            </span>
                        )}
                    </label>
                    <input
                        type="tel"
                        placeholder="Enter Staff Phone"
                        required
                        value={assignServiceStaffPhone}
                        onChange={(e) => {
                            setAssignServiceStaffPhone(e.target.value);
                            assignServicePhoneToStaff(e.target.value);
                        }}
                        style={{
                            border:
                                staffAttendanceStatus === "present"
                                    ? "2px solid green"
                                    : staffAttendanceStatus === "absent"
                                    ? "2px solid red"
                                    : "1px solid #ccc",
                            backgroundColor:
                                staffAttendanceStatus === "present"
                                    ? "#e8fbe8"
                                    : staffAttendanceStatus === "absent"
                                    ? "#fdeaea"
                                    : "white"
                        }}
                    />
                    <label>preferred_date : {servicePreferedDate}</label>
                    <label>Scheduled Date : </label>
                    <input placeholder='Enter Scheduled Date' type='date' value={assignServiceDate} onChange={(e)=>{setAssignServiceDate(e.target.value)}} required/>
                    <button type="submit">Submit</button>
                </form>
            </div>
        </div>:<></>}
            <div className='service-top'>
                <div className='service-top-main'>
                    
                    <button className='service-top-box' onClick={getPendingServiceList}>
                        <div className='service-top-box-cont'>
                            <p className='service-top-value'>{boxData.pending}</p>
                            <p className='service-top-title'>Pending Services</p>
                        </div>
                        <TiWarning className="service-top-box-icon" size={50} color='red' />
                    </button>
                    <button className='service-top-box' onClick={getAssignedServiceList}>
                        <div className='service-top-box-cont'>
                            <p className='service-top-value'>{boxData.assigned}</p>
                            <p className='service-top-title'>Assigned Services</p>
                        </div>
                        <MdUpcoming className="service-top-box-icon" size={50} color='#e305a0' />
                    </button>
                    <button className='service-top-box' onClick={getCompletedServiceList}>
                        <div className='service-top-box-cont'>
                            <p className='service-top-value'>{boxData.completed}</p>
                            <p className='service-top-title'>Completed Services</p>
                        </div>
                        <MdVerified className="service-top-box-icon" size={50} color='green' />
                    </button>
                    <button className='service-top-box' onClick={getAllServiceList}>
                        <div className='service-top-box-cont'>
                            <p className='service-top-value'>{boxData.total}</p>
                            <p className='service-top-title'>Total Services</p>
                        </div>
                        <PiStackSimpleFill className="service-top-box-icon" size={50} color='#ff7300' />
                    </button>
                </div>
            </div>

            <div className='service-bottom'>
                <div className='service-bottom-main'>
                    <div className='service-bottom-left'>
                        <div className='service-bottom-left-top'>
                            <select value={searchType} onChange={(e) => setSearchType(e.target.value)}>
                                <option value="id">Search by ID</option>
                                <option value="phone">Search by Phone</option>
                                <option value="name">Search by Name</option>
                            </select>
                            <input
                                type="text"
                                placeholder={`Enter ${searchType}`}
                                value={searchQuery}
                                onChange={(e) => setSearchQuery(e.target.value)}
                            />
                            <select value={sortBy} onChange={(e) => setSortBy(e.target.value)}>
                                <option value="latest">Newest First</option>
                                <option value="oldest">Oldest First</option>
                                <option value="status">Sort by Status</option>
                                <option value="customer">Sort by Customer Name</option>
                            </select>
                        </div>

                        <div className='service-bottom-table-cont'>
                            <table className="service-list">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Booked Date</th>
                                        <th>Customer</th>
                                        <th>Staff</th>
                                        <th>Complaint</th>
                                        <th>Status</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {filteredList.map((service) => (
                                        <tr key={service.id} onClick={() => {
                                            updateServiceFormWithID(service.id);
                                            setEditService(true);
                                        }} style={{ cursor: 'pointer' }}>
                                            <td>{service.id}</td>
                                            <td>{formatDate(service.created_at)}</td>
                                            <td>{service.customer_data.name}</td>
                                            <td>{service.assigned_to_detail!=null?service.assigned_to_detail["name"]:"Not Assigned"}</td>
                                            <td>{service.description}</td>
                                            <td>{service.status}</td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    </div>

                    <div className='service-bottom-right'>
                        <div className='service-bottom-right-cont'>
                            <div className='service-bottom-right-top'>
                                <div className='service-bottom-right-top-cont'>
                                    <p className='service-bottom-right-top-left'>{editService ? ("Edit Service"):("Create Service")}</p>
                                    <div className='service-bottom-right-top-right'>
                                        <button title='Create Service' onClick={()=>setEditService(false)} className={editService?'service-bottom-right-top-right-no-active':'service-bottom-right-top-right-active'}><MdAddToPhotos/>&nbsp;&nbsp;&nbsp;Create</button>
                                        <button title='Edit Service' onClick={()=>setEditService(true)} className={editService?'service-bottom-right-top-right-active':'service-bottom-right-top-right-no-active'}><RiEdit2Fill/>&nbsp;&nbsp;&nbsp;Edit</button>
                                    </div>
                                </div>
                            </div>

                            <div className='service-bottom-right-bottom'>
                                {editService ? 
                                (
                                    <div className='service-bottom-right-bottom-edit-cont'>
                                        <div className='service-bottom-right-bottom-edit-fetch-box'>
                                            <form className='service-bottom-right-bottom-edit-fetch' onSubmit={(e)=>{e.preventDefault();updateServiceFormWithID(fetchServiceId);}}>
                                                <input type="text" placeholder='Enter Service ID' className='service-bottom-right-bottom-edit-input' value={fetchServiceId} onChange={(e)=>{setFetchServiceId(e.target.value)}} required/>
                                                <button className='service-bottom-right-bottom-edit-button' type='submit'>Fetch</button>
                                            </form>
                                        </div>
                                        <hr/>
                                        {serviceFetch ?
                                        (
                                        <div className='service-bottom-right-bottom-edit-info-box'>
                                            <div className='service-bottom-right-bottom-edit-info-cont'>
                                                <p className='service-bottom-right-bottom-edit-info-title'>Service ID</p>
                                                <input className='service-bottom-right-bottom-edit-info-input' value={serviceID} disabled/>
                                            </div>
                                            <div className='service-bottom-right-bottom-edit-info-cont'>
                                                <p className='service-bottom-right-bottom-edit-info-title'>Customer Preferred Date</p>
                                                <input className='service-bottom-right-bottom-edit-info-input' value={formatDate(servicePreferedDate)} disabled/>
                                            </div>
                                            <div className='service-bottom-right-bottom-edit-info-cont'>
                                                <p className='service-bottom-right-bottom-edit-info-title'>Customer Address</p>
                                                <input className='service-bottom-right-bottom-edit-info-input' value={serviceAddress} disabled/>
                                            </div>
                                            <div className='service-bottom-right-bottom-edit-info-cont'>
                                                <p className='service-bottom-right-bottom-edit-info-title'>Staff ID</p>
                                                <input
                                                    type="text"
                                                    placeholder='Enter Staff ID'
                                                    className='service-bottom-right-bottom-edit-info-input'
                                                    value={serviceStaffID}
                                                    onChange={(e)=>{setServiceStaffID(e.target.value)}}
                                                    style={{
                                                        border:
                                                            staffAttendanceStatus === "present"
                                                                ? "2px solid green"
                                                                : staffAttendanceStatus === "absent"
                                                                ? "2px solid red"
                                                                : "1px solid #ccc",
                                                        backgroundColor:
                                                            staffAttendanceStatus === "present"
                                                                ? "#e8fbe8"
                                                                : staffAttendanceStatus === "absent"
                                                                ? "#fdeaea"
                                                                : "white"
                                                    }}
                                                />
                                                {isToday(serviceScheduleDate) && staffAttendanceStatus && (
                                                    <p
                                                        style={{
                                                            marginTop: "4px",
                                                            color: staffAttendanceStatus === "present" ? "green" : "red",
                                                            fontWeight: "bold"
                                                        }}
                                                    >
                                                        {staffAttendanceStatus === "present"
                                                            ? "Staff Present Today"
                                                            : "Staff Absent Today"}
                                                    </p>
                                                )}


                                            </div>
                                            {/* <div className='service-bottom-right-bottom-edit-info-cont'>
                                                <p className='service-bottom-right-bottom-edit-info-title'>Card ID</p>
                                                <input type="text" placeholder='Enter Card ID' className='service-bottom-right-bottom-edit-info-input' value={serviceCardID} onChange={(e)=>{setServiceCardID(e.target.value)}}/>
                                            </div> */}
                                            
                                            <div className='service-bottom-right-bottom-edit-info-cont'>
                                                <p className='service-bottom-right-bottom-edit-info-title'>Scheduled Date</p>
                                                <input type="date" placeholder='Enter Available' className='service-bottom-right-bottom-edit-info-input' value={serviceScheduleDate} onChange={(e)=>{setServiceScheduleDate(e.target.value)}}/>
                                            </div>
                                            <div className='service-bottom-right-bottom-edit-info-cont'>
                                                <p className='service-bottom-right-bottom-edit-info-title'>Next Service On</p>
                                                <input type="date" placeholder='Enter Available' className='service-bottom-right-bottom-edit-info-input' value={serviceNextServiceDate} onChange={(e)=>{setServiceNextServiceDate(e.target.value)}}/>
                                            </div>
                                            <div className='service-bottom-right-bottom-edit-info-cont'>
                                                <p className='service-bottom-right-bottom-edit-info-title'>Complaint</p>
                                                <input type="text" placeholder='Enter Complaint' className='service-bottom-right-bottom-edit-info-input' value={serviceDescription} onChange={(e)=>{setServiceDescription(e.target.value)}}/>
                                            </div>
                                            <div className='service-bottom-right-bottom-edit-info-cont'>
                                                <p className='service-bottom-right-bottom-edit-info-title'>Service Type</p>
                                                <select
                                                    className='service-bottom-right-bottom-edit-info-input-drop'
                                                    value={serviceType}
                                                    onChange={(e) => setServiceType(e.target.value)}
                                                >
                                                    <option value="normal">Normal Service</option>
                                                    <option value="free">Free Service (Warrenty)</option>
                                                </select>
                                            </div>
                                            <div className='service-bottom-right-bottom-edit-info-cont'>
                                                <p className='service-bottom-right-bottom-edit-info-title'>Service Visit Type</p>
                                                <select
                                                    className='service-bottom-right-bottom-edit-info-input-drop'
                                                    value={serviceVisitType}
                                                    onChange={(e) => setServiceVisitType(e.target.value)}
                                                >
                                                    <option value="I">Installation</option>
                                                    <option value="C">Complaint</option>
                                                    <option value="MS">Mandatory Service</option>
                                                    <option value="CS">Contract Service</option>
                                                    <option value="CC">Curtacy Call</option>
                                                </select>
                                            </div>
                                            <div className='service-bottom-right-bottom-edit-info-cont'>
                                                <p className='service-bottom-right-bottom-edit-info-title'>Status</p>
                                                <select
                                                    className='service-bottom-right-bottom-edit-info-input-drop'
                                                    value={serviceStatus}
                                                    onChange={(e) => setServiceStatus(e.target.value)}
                                                >
                                                    <option value="">Select Status</option>
                                                    <option value="pending">Pending</option>
                                                    <option value="scheduled">Scheduled</option>
                                                    <option value="assigned">Assigned</option>
                                                    <option value="in_progress">In Progress</option>
                                                    <option value="awaiting_otp">Awaiting OTP</option>
                                                    <option value="completed">Completed</option>
                                                    <option value="cancelled">Cancelled</option>
                                                </select>
                                            </div>
                                            
                                            <div className='service-bottom-right-bottom-edit-info-cont'>
                                                <p className='service-bottom-right-bottom-edit-info-title'>Customer ID</p>
                                                <input className='service-bottom-right-bottom-edit-info-input' value={serviceCustomerID} disabled/>
                                            </div>
                                            <div className='service-bottom-right-bottom-edit-info-cont'>
                                                <p className='service-bottom-right-bottom-edit-info-title'>Customer Booked Date</p>
                                                <input className='service-bottom-right-bottom-edit-info-input' value={formatDate(serviceBookedDate)} disabled/>
                                            </div>
                                            
                                            {
                                                serviceOtpPhone!=null?
                                                (
                                                    <div className='service-bottom-right-bottom-edit-info-cont'>
                                                        <p className='service-bottom-right-bottom-edit-info-title'>OTP Send To</p>
                                                        <input className='service-bottom-right-bottom-edit-info-input' value={serviceOtpPhone} disabled/>
                                                    </div>
                                                ):<div></div>
                                            }
                                            {
                                                serviceHasFeedback?
                                                (
                                                    <div className='service-bottom-right-bottom-edit-info-cont'>
                                                        <p className='service-bottom-right-bottom-edit-info-title'>Rating : {serviceRating}/5</p>
                                                    </div>
                                                ):<div></div>
                                            }
                                            {
                                                serviceHasFeedback?
                                                (
                                                    <div className='service-bottom-right-bottom-edit-info-cont'>
                                                        <p className='service-bottom-right-bottom-edit-info-title'>Feedback : {serviceFeedback}</p>
                                                    </div>
                                                ):<div></div>
                                            }
                                        </div>
                                        ):
                                        (
                                            <div className='service-bottom-right-bottom-edit-no-info-cont'>
                                                <p>Enter ID and Fetch the data</p>
                                            </div>
                                        )}
                                        <hr/>
                                        <div className='service-bottom-right-bottom-edit-button-cont'>
                                            <button className='service-bottom-right-bottom-edit-submit' onClick={editServiceForm}>Edit Service</button>
                                            {serviceStatus=="pending"?
                                                <button className='service-bottom-right-bottom-edit-submit-as' onClick={()=>{setShowAssignStaffForm(true)}}>Assign Staff</button>:<></>
                                            }
                                        </div>
                                    </div>
                                ):
                                (

                                    <form className='service-bottom-right-bottom-create-cont' onSubmit={(e)=>{e.preventDefault();bookService();}}>
                                        <div className='service-bottom-right-bottom-create-info-box'>
                                            <div className='service-bottom-right-bottom-create-info-cont'>
                                                <p className='service-bottom-right-bottom-create-info-title'>Customer : {createServiceCustomer!=null?createServiceCustomer["name"] + " ( " + createServiceCustomer["id"] + " )" : "Not Found"}</p>
                                                <input type="text" placeholder='Enter Customer Phone' className='service-bottom-right-bottom-create-info-input' required value={createServiceCustomerPhone} onChange={(e)=>{setCreateServiceCustomerPhone(e.target.value); assignPhoneToCustomer(e.target.value)}} />
                                            </div>
                                            
                                            <div className='service-bottom-right-bottom-create-info-cont-drop'>
                                                <p className='service-bottom-right-bottom-create-info-title'>Card ID : </p>
                                                <select
                                                    className='service-bottom-right-bottom-create-info-input'
                                                    required
                                                    value={createServiceCardID}
                                                    onChange={(e) => setcreateServiceCardID(e.target.value)}
                                                >
                                                    <option value="">-- Select Card --</option>
                                                    {createServiceCardAll.map((card) => (
                                                    <option key={card.id} value={card.id}>
                                                        {card.id + " - " + card.model}
                                                    </option>
                                                    ))}
                                                </select>
                                            </div>

                                            <div className='service-bottom-right-bottom-create-info-cont'>
                                                <p className='service-bottom-right-bottom-create-info-title'>Staff : {createServiceStaff!=null?createServiceStaff["name"] + " ( " + createServiceStaff["id"] + " )" : "Not Found"}</p>
                                                <input
                                                    type="text"
                                                    placeholder='Enter Staff Phone'
                                                    className='service-bottom-right-bottom-create-info-input'
                                                    required
                                                    value={createServiceStaffPhone}
                                                    onChange={(e)=>{
                                                        setCreateServiceStaffPhone(e.target.value);
                                                        assignPhoneToStaff(e.target.value);
                                                    }}
                                                    style={{
                                                        border:
                                                            createStaffAttendanceStatus === "present"
                                                                ? "2px solid green"
                                                                : createStaffAttendanceStatus === "absent"
                                                                ? "2px solid red"
                                                                : "1px solid #ccc",
                                                        backgroundColor:
                                                            createStaffAttendanceStatus === "present"
                                                                ? "#e8fbe8"
                                                                : createStaffAttendanceStatus === "absent"
                                                                ? "#fdeaea"
                                                                : "white"
                                                    }}
                                                />

                                            </div>
                                            <div className='service-bottom-right-bottom-create-info-cont'>
                                                <p className='service-bottom-right-bottom-create-info-title'>Scheduled Date</p>
                                                <input type="date" className='service-bottom-right-bottom-create-info-input' required value={createServiceDate} onChange={(e)=>{setCreateServiceDate(e.target.value)}}/>
                                            </div>
                                            <div className='service-bottom-right-bottom-create-info-cont-drop'>
                                                <p className='service-bottom-right-bottom-create-info-title'>Visit Type :</p>
                                                <select
                                                    className='service-bottom-right-bottom-create-info-input'
                                                    value={createServiceVisitType}
                                                    onChange={(e) => setCreateServiceVisitType(e.target.value)}
                                                >
                                                    <option value="I">Installation</option>
                                                    <option value="C">Complaint</option>
                                                    <option value="MS">Mandatory Service</option>
                                                    <option value="CS">Contract Service</option>
                                                    <option value="CC">Curtacy Call</option>
                                                </select>
                                            </div>
                                            <div className='service-bottom-right-bottom-create-info-cont-drop'>
                                                <p className='service-bottom-right-bottom-create-info-title'>Is Free :</p>
                                                <select
                                                    className='service-bottom-right-bottom-create-info-input'
                                                    value={createServiceType}
                                                    onChange={(e) => setCreateServiceType(e.target.value)}
                                                >
                                                    <option value="normal">Normal Service</option>
                                                    <option value="free">Free Service (Warrenty)</option>
                                                </select>
                                            </div>
                                            <div className='service-bottom-right-bottom-create-info-cont'>
                                                <p className='service-bottom-right-bottom-create-info-title'>Complaint</p>
                                                <input type="text" required placeholder='Enter Complaint' className='service-bottom-right-bottom-create-info-input' value={createServiceDescription} onChange={(e)=>{setCreateServiceDescription(e.target.value)}}/>
                                            </div>


                                        </div>
                                        <hr/>
                                        <div className='service-bottom-right-bottom-edit-button-cont'>
                                            <button className='service-bottom-right-bottom-edit-submit' type='submit'>Create Service</button>
                                        </div>
                                    </form>
                                )}
                            </div>


                        </div>

                    </div>
                </div>
            </div>
        </div>
    );
};

export default Service;
