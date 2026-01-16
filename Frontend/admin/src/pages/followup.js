import '../styles/followup.css';
import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import Cookies from 'js-cookie';
import { useParams } from "react-router-dom";

const FollowUp = () => {

    const BASEURL = "http://157.173.220.208";
    const navigate = useNavigate();



    // +++++++++++++ FRONTEND UI ++++++++++++++++

    return (
        <div className='followup-main'>
            <p>FOLLOWUP</p>
        </div>
    );
};

export default FollowUp;
