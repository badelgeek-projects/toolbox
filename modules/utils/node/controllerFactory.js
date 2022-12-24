const generateCrudController = (model) => {
  const controller = {
    getAll: async (req, res, next) => {
      try {
        const allElements = await model.findAll();
        res.json(allElements);
      } catch (error) {
        next(error);
      }
    },

    createOne: async (req, res, next) => {
      try {
        const element = await model.create(req.body);
        if (!element) {
          return res.sendStatus(404);
        }
        res.json(element);
      } catch (error) {
        next(error);
      }
    },

    getOne: async (req, res, next) => {
      const id = +req.params.id;
      try {
        const element = await model.findByPk(id);
        if (!element) {
          return res.sendStatus(404);
        }
        res.json(element);
      } catch (error) {
        next(error);
      }
    },

    updateOne: async (req, res, next) => {
      const id = +req.params.id;
      try {
        const element = await model.findByPk(id);
        if (!element) {
          return res.sendStatus(404);
        }
        const result = await element.update(req.body);
        res.json(result);
      } catch (error) {
        next(error);
      }
    },

    deleteOne: async (req, res, next) => {
      const id = +req.params.id;
      try {
        const deletedCount = await model.destroy({ where: { id } });
        if (!deletedCount) {
          return res.sendStatus(404);
        }
        res.sendStatus(204);
      } catch (error) {
        next(error);
      }
    },
  };

  return controller;
};

module.exports = { generateCrudController };
