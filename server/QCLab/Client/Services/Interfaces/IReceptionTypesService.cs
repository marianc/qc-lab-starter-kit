using QCLab.Client.Dtos;

namespace QCLab.Client.Services.Interfaces
{
    public interface IReceptionTypesService
    {
        Task<List<ReceptionTypeDto>> GetAllReceptionTypes();
    }
}