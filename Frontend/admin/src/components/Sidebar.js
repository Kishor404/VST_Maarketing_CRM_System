import React from "react";
import { Link } from "react-router-dom";
import { FaUsers, FaIdBadge, FaEdit, FaInfo, FaAddressCard, FaPlus } from "react-icons/fa";
import { MdRoomService } from "react-icons/md";
import { MdHotelClass } from "react-icons/md";
import '../styles/sidebar.css';
import Logo from '../assets/logo.jpg';
import Cookies from 'js-cookie';

const Sidebar = () => {
    const name = Cookies.get('name');
    const region = Cookies.get('region');
return (
    <div className="sidebar">
        <div className="sidebar-main">
            <div className="sidebar-img-cont">
                <img src={Logo} alt="VST Maarketing" className="sidebar-img"/>
            </div>
            <div className="sidebar-button-cont">
                <Link to="/head/createcard" className="sidebar-button">
                    Create Card
                    <FaPlus className="sidebar-button-icon" size={12}/>
                </Link>
            </div>
            <div className="sidebar-list">
                <div className="sidebar-item">
                    <Link to="/head/service" className="sidebar-link">
                        <MdRoomService className="sidebar-item-icon" size={20}/>
                        Services
                    </Link>
                </div>
                <div className="sidebar-item">
                    <Link to="/head/warranty" className="sidebar-link">
                        <MdHotelClass className="sidebar-item-icon" size={20}/>
                        Warranty
                    </Link>
                </div>
                <div className="sidebar-item">
                    <Link to="/head/customer" className="sidebar-link">
                        <FaUsers className="sidebar-item-icon" size={20}/>
                        Customers
                    </Link>
                </div>
                <div className="sidebar-item">
                    <Link to="/head/staff" className="sidebar-link">
                        <FaIdBadge className="sidebar-item-icon" size={20}/>
                        Staffs
                    </Link>
                </div>
                <div className="sidebar-item">
                    <Link to="/head/attendance" className="sidebar-link">
                        <FaInfo className="sidebar-item-icon" size={20}/>
                        Attendance
                    </Link>
                </div>
                <div className="sidebar-item">
                    <Link to="/head/showcard" className="sidebar-link">
                        <FaAddressCard className="sidebar-item-icon" size={20}/>
                        Customer Card
                    </Link>
                </div>
            </div>
            <div className="sidebar-profile-cont">
                <div className="sidebar-profile">
                    <p className="sidebar-profile-name">{name}</p>
                    <p className="sidebar-profile-city">{region}</p>
                    <button>LOGOUT</button>
                </div>
            </div>
        </div>
    </div>
);
};

export default Sidebar;
