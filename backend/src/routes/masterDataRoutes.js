const express = require('express');
const router = express.Router();
const masterDataController = require('../controllers/masterDataController');
const { verifyToken, authorizeRoles } = require('../middleware/auth');

// Public or Protected? Usually Protected.
// For now, let's make read public/protected, write admin only.

router.get('/countries', verifyToken, masterDataController.getCountries);
router.post('/countries', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.createCountry);
router.put('/countries/:id', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.updateCountry);
router.delete('/countries/:id', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.deleteCountry);
router.post('/countries/seed', verifyToken, authorizeRoles('GlobalAdmin'), masterDataController.seedCountries);

router.get('/branches', verifyToken, masterDataController.getBranches);
router.post('/branches', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.createBranch);
router.put('/branches/:id', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.updateBranch);
router.delete('/branches/:id', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.deleteBranch);

router.get('/holidays', verifyToken, masterDataController.getHolidays);
router.post('/holidays', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.createHoliday);

router.get('/departments', verifyToken, masterDataController.getDepartments);
router.post('/departments', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.createDepartment);
router.put('/departments/:id', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.updateDepartment);
router.delete('/departments/:id', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.deleteDepartment);

router.get('/users', verifyToken, masterDataController.getUsers);
router.post('/users', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.createUser);
router.put('/users/:id', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.updateUser);
router.delete('/users/:id', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.deleteUser);

// Categories
router.get('/categories', verifyToken, masterDataController.getCategories);
router.post('/categories', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.createCategory);
router.put('/categories/:id', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.updateCategory);
router.delete('/categories/:id', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.deleteCategory);
router.post('/categories/seed', verifyToken, authorizeRoles('GlobalAdmin'), masterDataController.seedCategories);

// Priorities
router.get('/priorities', verifyToken, masterDataController.getPriorities);
router.post('/priorities', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.createPriority);
router.put('/priorities/:id', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.updatePriority);
router.delete('/priorities/:id', verifyToken, authorizeRoles('GlobalAdmin', 'BranchManager'), masterDataController.deletePriority);
router.post('/priorities/seed', verifyToken, authorizeRoles('GlobalAdmin'), masterDataController.seedPriorities);

module.exports = router;
