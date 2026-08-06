const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

const MONGO_URI = 'mongodb://localhost:27017/attendance_app';

mongoose.connect(MONGO_URI)
  .then(() => console.log('MongoDB Connected Successfully!'))
  .catch((err) => console.log('DB Connection Error:', err));

// User Schema (Roles: student, teacher, admin)
const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  role: { type: String, enum: ['student', 'teacher', 'admin'], required: true }
});
const User = mongoose.model('User', userSchema);

// Active Session Schema (Teacher OTP)
const sessionSchema = new mongoose.Schema({
  teacherId: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  otp: { type: String, required: true },
  date: { type: String, required: true },
  createdAt: { type: Date, default: Date.now, expires: 60 } // 60 seconds expiry
});
const Session = mongoose.model('Session', sessionSchema);

// Attendance Schema
const attendanceSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  userName: { type: String, required: true },
  role: { type: String, enum: ['student', 'teacher'], required: true },
  date: { type: String, required: true },
  status: { type: String, default: 'Present' },
  timestamp: { type: Date, default: Date.now }
});
const Attendance = mongoose.model('Attendance', attendanceSchema);
// Get All Users for Admin Portal
app.get('/api/admin/users', async (req, res) => {
  try {
    const users = await User.find({}, { password: 0 }); // Password chhod kar saari details
    res.status(200).json(users);
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// 1. Register API
app.post('/api/register', async (req, res) => {
  try {
    const { name, email, password, role } = req.body;
    const existingUser = await User.findOne({ email });
    if (existingUser) return res.status(400).json({ message: 'User already exists' });

    const newUser = new User({ name, email, password, role });
    await newUser.save();
    res.status(201).json({ message: 'Registered successfully', user: newUser });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// 2. Login API
app.post('/api/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (!user || user.password !== password) {
      return res.status(400).json({ message: 'Invalid credentials' });
    }
    res.status(200).json({ message: 'Login successful', user });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// 3. Password Reset API (For Student, Teacher, and Admin)
app.post('/api/reset-password', async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ message: 'User not found with this email!' });
    }

    user.password = newPassword;
    await user.save();
    res.status(200).json({ message: 'Password reset successfully!' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// 4. Teacher Start Session & Generate OTP
app.post('/api/teacher/start-session', async (req, res) => {
  try {
    const { teacherId, teacherName, date } = req.body;

    const existingTeacherAtt = await Attendance.findOne({ userId: teacherId, date });
    if (!existingTeacherAtt) {
      await new Attendance({ userId: teacherId, userName: teacherName, role: 'teacher', date }).save();
    }

    const otp = Math.floor(1000 + Math.random() * 9000).toString();

    await Session.deleteMany({ date });
    const newSession = new Session({ teacherId, otp, date });
    await newSession.save();

    res.status(201).json({ message: 'Session started', otp });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// 5. Student Mark Attendance via OTP
app.post('/api/student/mark-attendance', async (req, res) => {
  try {
    const { studentId, studentName, otp, date } = req.body;

    const activeSession = await Session.findOne({ otp, date });
    if (!activeSession) {
      return res.status(400).json({ message: 'Invalid or Expired OTP!' });
    }

    const existingAtt = await Attendance.findOne({ userId: studentId, date });
    if (existingAtt) {
      return res.status(400).json({ message: 'Attendance already marked for today!' });
    }

    await new Attendance({ userId: studentId, userName: studentName, role: 'student', date }).save();
    res.status(201).json({ message: 'Attendance marked successfully!' });
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

// 6. Reports & Percentage API
// 6. Reports & Percentage API (Dynamic Month & Year Wise Calculation)
app.get('/api/reports/:userId/:role', async (req, res) => {
  try {
    const { userId, role } = req.params;

    if (role === 'admin') {
      const totalStudents = await User.countDocuments({ role: 'student' });
      const totalTeachers = await User.countDocuments({ role: 'teacher' });
      const today = new Date().toISOString().split('T')[0];
      
      const todayPresentStudents = await Attendance.countDocuments({ role: 'student', date: today });
      const todayPresentTeachers = await Attendance.countDocuments({ role: 'teacher', date: today });

      const allAttendance = await Attendance.find().sort({ timestamp: -1 });

      return res.status(200).json({
        totalStudents,
        totalTeachers,
        todayPresentStudents,
        todayPresentTeachers,
        allAttendance
      });
    } else {
      const userAttendances = await Attendance.find({ userId }).sort({ timestamp: -1 });
      
      const now = new Date();
      const currentYear = now.getFullYear();
      const currentMonth = now.getMonth(); // 0 = January, 7 = August, etc.

      // 1. Current Month ke total days nikalna (Jaise August mein 31 days)
      // Working days ke liye hum weekends (Saturday/Sunday) ko hata sakte hain ya total days rakh sakte hain. 
      // Yahan hum standard working days (approx 22 days per month ya total days) maan sakte hain.
      const getDaysInMonth = (year, month) => new Date(year, month + 1, 0).getDate();
      const totalDaysThisMonth = getDaysInMonth(currentYear, currentMonth);
      
      // Maan lete hain ek month mein roughly 22 working days hote hain (Sunday/Holidays exclude karke)
      // Aap chahein toh totalDaysThisMonth bhi use kar sakte hain.
      const estimatedWorkingDaysThisMonth = Math.floor(totalDaysThisMonth * (22 / 31)); 

      // Is month mein user kitne din present raha uski count
      const presentThisMonth = userAttendances.filter(att => {
        const attDate = new Date(att.date);
        return attDate.getFullYear() === currentYear && attDate.getMonth() === currentMonth;
      }).length;

      let monthlyPercentage = 0;
      if (estimatedWorkingDaysThisMonth > 0) {
        monthlyPercentage = ((presentThisMonth / estimatedWorkingDaysThisMonth) * 100).toFixed(1);
      }

      // 2. Year ke start se lekar aaj tak ke total working days (January se lekar aaj tak)
      // Har mahine ke 22 working days count karte hain
      let totalWorkingDaysSoFar = 0;
      for (let m = 0; m <= currentMonth; m++) {
        const daysInM = getDaysInMonth(currentYear, m);
        totalWorkingDaysSoFar += Math.floor(daysInM * (22 / 31));
      }

      const totalPresentYear = userAttendances.filter(att => {
        const attDate = new Date(att.date);
        return attDate.getFullYear() === currentYear;
      }).length;

      let yearlyPercentage = 0;
      if (totalWorkingDaysSoFar > 0) {
        yearlyPercentage = ((totalPresentYear / totalWorkingDaysSoFar) * 100).toFixed(1);
      }

      // Cap percentages to max 100%
      if (parseFloat(monthlyPercentage) > 100) monthlyPercentage = '100.0';
      if (parseFloat(yearlyPercentage) > 100) yearlyPercentage = '100.0';

      return res.status(200).json({
        presentDays: totalPresentYear, // Total present days in year
        percentage: monthlyPercentage, // Current month percentage (ya aap yearly bhi dikha sakte hain)
        monthlyPercentage: monthlyPercentage,
        yearlyPercentage: yearlyPercentage,
        history: userAttendances
      });
    }
  } catch (error) {
    res.status(500).json({ message: 'Server error', error: error.message });
  }
});

const PORT = 5000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));