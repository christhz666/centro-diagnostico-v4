const express = require('express');
const router = express.Router();
const {
    getFacturas, getFactura, createFactura,
    anularFactura, getResumen
} = require('../controllers/facturaController');
const { protect, authorize } = require('../middleware/auth');
const { idValidation } = require('../middleware/validators');

router.use(protect);

router.get('/resumen', authorize('admin'), getResumen);

router.route('/')
    .get(getFacturas)
    .post(authorize('admin', 'recepcion'), createFactura);

router.route('/:id')
    .get(idValidation, getFactura);

router.patch('/:id/anular', idValidation, authorize('admin'), anularFactura);

module.exports = router;
